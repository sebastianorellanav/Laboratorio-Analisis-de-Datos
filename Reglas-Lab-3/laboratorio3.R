######################################################################################################
###########################    Laboratorio 2 - Analisis de Datos    ##################################
######################################################################################################
###########################    Autores:     Gary Simken             ##################################
###########################                 Sebasti?n Orellana      ##################################
###########################    Fecha:       18 - Junio - 2021       ##################################
######################################################################################################

######################################################################################################
##########################            Bibliotecas          ###########################################
library(modeest)
library(ggplot2)
library(ggpubr)
library(cowplot)
library(ggcorrplot)
library(reshape2)
library(RColorBrewer)
library(missForest)
library(factoextra)
library(cluster)
library(arulesViz)
library(NbClust)

# Se limpia el ambiente de variables y los graficos antiguos
rm(list=ls())
if(length(dev.list())!=0){
  dev.off(dev.list()["RStudioGD"])
}




######################################################################################################
##########################            Data-set             ###########################################

#1. Sample code number: id number
#2. Clump Thickness: 1 - 10             CT
#3. Uniformity of Cell Size: 1 - 10     UCS
#4. Uniformity of Cell Shape: 1 - 10    UCSH
#5. Marginal Adhesion: 1 - 10           MA
#6. Single Epithelial Cell Size: 1 - 10 SECS
#7. Bare Nuclei: 1 - 10                 BN
#8. Bland Chromatin: 1 - 10             BC
#9. Normal Nucleoli: 1 - 10             NN
#10. Mitoses: 1 - 10                    M
#11. Class: (2 for benign, 4 for malignant) C

# Se definen los nombres de las columnas, estos son los mismos de provistos por la base de datos
columnas = c("id",
             "clumpThickness",
             "uniformityCellSize",
             "uniformityCellShape",
             "marginalAdhesion",
             "singleEpithCellSize",
             "bareNuclei",
             "blandChromatin",
             "normalNucleoli",
             "mitoses",
             "class"
)
# Se importa la base de dato mediante la url del repositorio UCI Machine Learning
url = "https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/breast-cancer-wisconsin.data"
df = read.csv(url, 
              header = F, 
              sep=",", 
              col.names = columnas)

# Se setea una semilla para las funciones que necesites utilizar nnumeros aleatorios
set.seed(1234)




######################################################################################################
##########################        Limpieza de Datos        ###########################################

# Se eliminan las variables if y class, dado que son datos no relevantes en esta parte del estudio,
# en el caso de id es un simple identificador por lo que no aporta y en el caso de clase, esta es 
# eliminada porque el Clustering es un m??todo no supervisado.
df <- subset(df, select = -c(id))
df.inicial<-df
df.inicial$class = factor(df.inicial$class, levels = c(2,4), labels = c("Benigno", "Maligno"))

# Resumen de los cuartiles de cada variable
summary(df)

# Para los datos "missing" se procede a cambiar los signos de interrogacisn por un NA, que es el valor
# default en los enteros cuando no existe un dato
df$bareNuclei[df$bareNuclei == "?"] = NA

# Por otro lado convertiremos todos los datos a tipo numerico para que no existan problemas al 
# momento de analizarlos
df[ , ] = apply(df[ , ], 2,function(x) as.numeric(as.character(x)) )

# Para reemplazar los valores nulos por datos que aporten al data-set se utiliza el metodo
# RandomForest
forestImp <- missForest(df)

# Valores imputados
df.forestImp <- forestImp$ximp
df.forestImp$bareNuclei <- round(df.forestImp$bareNuclei)

# Se guardan los nuevos datos
df<- df.forestImp
df$class<-df.inicial$class

# Se procede a realizar un grafico de cajas por cada variable para identificar los posibles
# ouliers que puedan existir. Para esto se conviernten los datos a tipo long para ser graficados
datos.long<-melt(df)

# Se crea un grafico de cajas
bp <- ggboxplot(datos.long,
                x = "variable", 
                y = "value",
                fill = "variable")

# Se muestra el grafico
print(bp)

# Se Cambian los outliers encontrados por la media de la correspondiente variable
df$marginalAdhesion[df$marginalAdhesion > 8] <- mean(df$marginalAdhesion)
df$singleEpithCellSize[df$singleEpithCellSize > 7] <- mean(df$singleEpithCellSize)
df$blandChromatin[df$blandChromatin > 9] <- mean(df$blandChromatin)
df$normalNucleoli[df$normalNucleoli > 8] <- mean(df$normalNucleoli)
df$mitoses[df$mitoses > 1] <- mean(df$mitoses)

#y regraficamos
# Se conviernten los datos a tipo long para ser graficados
datos.long<-melt(df)

# Se crea un grafico de cajas
bp <- ggboxplot(datos.long,
                x = "variable", 
                y = "value",
                fill = "variable")

print(bp)
#luego Balanceamos las clases para poder trabajar correctamente con las reglas
i <- which(df[["class"]] == "Benigno")
j <- which(df[["class"]] == "Maligno")

N <- sum(df$class=="Maligno")
i <- sample(i, N)
j <- sample(j, N)
df <- df[c(i, j), ]

#y regraficamos
# Se conviernten los datos a tipo long para ser graficados
datos.long<-melt(df)

# Se crea un grafico de cajas
bp <- ggboxplot(datos.long,
                x = "variable", 
                y = "value",
                fill = "variable")

# Se muestra el grafico
print(bp)

#Revisamos un resumen de las clases
summary(df[df$class=="Benigno",])
summary(df[df$class=="Maligno",])


# Se crea una funci?n para comparar cada variable con la clase de cancer
# a la cual pertence la observaci?n
grafico <- function(df,aes,y_string){
  boxplt =  ggboxplot(data = df, 
                      x = "class", 
                      y = y_string, 
                      color = "class",
                      add= "jitter") + border()
  
  ydens = axis_canvas(boxplt, 
                      axis = "y", 
                      coord_flip = TRUE) + 
    geom_density(data = df, 
                 aes, alpha = 0.7, 
                 size = 0.2) + 
    coord_flip()
  
  boxplt = insert_yaxis_grob(boxplt, 
                             ydens, 
                             grid::unit(.2, "null"), 
                             position = "right")
  ggdraw(boxplt)
  
}# Fin de la funci?n

# Se llama a la funci?n para crear los gr?ficos
a<-grafico(df,aes(x = clumpThickness, fill = class),"clumpThickness")
b<-grafico(df,aes(x = uniformityCellSize, fill = class),"uniformityCellSize")
c<-grafico(df,aes(x = uniformityCellShape, fill = class),"uniformityCellShape")
d<-grafico(df,aes(x = marginalAdhesion, fill = class),"marginalAdhesion")
e<-grafico(df,aes(x = singleEpithCellSize, fill = class),"singleEpithCellSize")
f<-grafico(df,aes(x = bareNuclei, fill = class),"bareNuclei")
g<-grafico(df,aes(x = blandChromatin, fill = class),"blandChromatin")
h<-grafico(df,aes(x = normalNucleoli, fill = class),"normalNucleoli")
i<-grafico(df,aes(x = mitoses, fill = class),"mitoses")
ggarrange(a,b,c,d)
ggarrange(e,f,g,h)
i
#Ahora buscando entre los graficos se aprecia que ClumpThickness y UniformityCellSize son buenos discriminadores


ggscatter(data = df, x = "clumpThickness", y = "bareNuclei", color = "class")


df.reglas=df
clumpThickness= c(-Inf, 5, Inf)
clumpThickness.names=c("Normal","Anormal")

uniformityCellSize= c(-Inf, 3, Inf)
uniformityCellSize.names=c("Normal","Anormal")

uniformityCellShape= c(-Inf, 3, Inf)
uniformityCellShape.names=c("Normal","Anormal")


marginalAdhesion= c(-Inf, 2, Inf)
marginalAdhesion.names=c("Normal","Anormal")


singleEpithCellSize= c(-Inf, 2.5, Inf)
singleEpithCellSize.names=c("Normal","Anormal")


bareNuclei= c(-Inf, 3, Inf)
bareNuclei.names=c("Normal","Anormal")


blandChromatin= c(-Inf, 3, Inf)
blandChromatin.names=c("Normal","Anormal")


normalNucleoli= c(-Inf, 2, Inf)
normalNucleoli.names=c("Normal","Anormal")


mitoses= c(-Inf, 1.2, Inf)
mitoses.names=c("Normal","Anormal")

df.reglas$clumpThickness=cut(df.reglas$clumpThickness, breaks = clumpThickness, labels = clumpThickness.names)
df.reglas$uniformityCellSize=cut(df.reglas$uniformityCellSize, breaks = uniformityCellSize, labels = uniformityCellSize.names)
df.reglas$uniformityCellShape=cut(df.reglas$uniformityCellShape, breaks = uniformityCellShape, labels = uniformityCellShape.names)
df.reglas$marginalAdhesion=cut(df.reglas$marginalAdhesion, breaks = marginalAdhesion, labels = marginalAdhesion.names)
df.reglas$singleEpithCellSize=cut(df.reglas$singleEpithCellSize, breaks = singleEpithCellSize, labels = singleEpithCellSize.names)
df.reglas$bareNuclei=cut(df.reglas$bareNuclei, breaks = bareNuclei, labels = bareNuclei.names)
df.reglas$blandChromatin=cut(df.reglas$blandChromatin, breaks = blandChromatin, labels = blandChromatin.names)
df.reglas$normalNucleoli=cut(df.reglas$normalNucleoli, breaks = normalNucleoli, labels = normalNucleoli.names)
df.reglas$mitoses=cut(df.reglas$mitoses, breaks = mitoses, labels = mitoses.names)


df.reglas[df.reglas$clumpThickness=="Normal" & df.reglas$bareNuclei=="Normal",]


rules = apriori(
  data = df.reglas, 
  parameter=list(support = 0.2, minlen = 2, maxlen = 6, target="rules"),
  appearance=list(rhs = c("class=Benigno", "class=Maligno"))
)


rules.sanos = apriori(
  data = df.reglas, 
  parameter=list(support = 0.2, minlen = 2, maxlen = 6, target="rules"),
  appearance=list(rhs = c("class=Benigno"))
)


rules.enfermos = apriori(
  data = df.reglas, 
  parameter=list(support = 0.2, minlen = 2, maxlen = 6, target="rules"),
  appearance=list(rhs = c("class=Maligno"))
)
rules.enfermos=sort(x = rules.enfermos, decreasing = TRUE, by = "confidence")
rules.sanos=sort(x = rules.sanos, decreasing = TRUE, by = "confidence")
rules=sort(x = rules, decreasing = TRUE, by = "confidence")
unlink("data.csv") # tidy up
write(rules, file = "data.csv", sep = ",")



