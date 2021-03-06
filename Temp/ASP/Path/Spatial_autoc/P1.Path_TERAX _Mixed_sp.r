rm(list=ls())

# PATH ANALYSIS TERAX 
# Included gaussian spatial autocorrelation
# Plot with PlotPath4.1 (-SAI) (Updated psem)

library(dplyr)
library(tidyr)
library(piecewiseSEM)
library(nlme)
library(MASS) # For correlation structures in glmm
library(aod)
#library(lme4)

setwd("C:/Users/Ana/Documents/PhD/First chapter/Datos/Datos barbechos arrendados/Variables")

sp <- read.csv("Data_path_submission2_sp.csv", sep = ",", header=TRUE, fill = TRUE)
sp <- sp[which(sp$Species == "LB"), ]

################################### PICAR Y HERBICIDAR #################################################################### 

e <- sp[ which(sp$agri_practice %in% c("C", "S+H")), ] #Select treatment

e <- e %>% 
  unnest(agri_practice) %>% 
  mutate(new = 1) %>% 
  spread(agri_practice, new, fill = 0) #Create dummy variable for treatment

length(which(e$Zone == "OCCIDENTAL" & e$`S+H` == "1")) # TREATMENT: 58 p+h and 88 Control en OCCIDENTAL
length(which(e$Zone == "ORIENTAL" & e$`S+H` == "1"))   #             2 p+h and 224 Control en ORIENTAL
length(which(e$Zone == "OCCIDENTAL" & e$C == "1")) 
length(which(e$Zone == "ORIENTAL" & e$C == "1")) 

e <- e[-which(e$Zone == "ORIENTAL"), ] # Delete oriental because only 0 and no use of Zone


colnames(e)[8] <- "Pres"
colnames(e)[12] <- "Diver"
colnames(e)[13] <- "Heter"
colnames(e)[16] <- "par"
colnames(e)[17] <- "Fallow"
colnames(e)[21] <- "crop_diver"
colnames(e)[25] <- "Treatment"

e$Cover<-scale(e$Cover)
e$Height<-scale(e$Height)
e$biom<-scale(e$biom)
e$Cover_dead<-scale(e$Cover_dead)
e$Heter<-scale(e$Heter)
e$Diver<-scale(e$Diver)
e$tbl<-scale(e$tbl)
e$par<-scale(e$par)
e$Fallow<-scale(e$Fallow)
e$crop_diver<-scale(e$crop_diver)
e$area <- scale(e$area)


#PATH ANALYSIS

# Random intercept Year. Include control=lmeControl(returnObject=TRUE) so that it works
e.list2 <- psem( 
  lme( Cover ~ Treatment, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e, control=lmeControl(returnObject=TRUE)))

e.fit2 <- summary(e.list2)

# Fill missing paths

e.list21 <- psem( 
  lme( Cover ~ Treatment + crop_diver + area, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment + crop_diver + area + Cover, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment + Cover, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment + crop_diver + Cover, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment + par + area + Cover + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height + area + Cover_dead + Diver, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e, control=lmeControl(returnObject=TRUE)))

e.fit21 <- summary(e.list21)
x2 <- rsquared(e.list21) # 0.26

e.coefs21 <- coefs(e.list21) 
e.coefs21$lowCI <- e.coefs21$Estimate - 2*e.coefs21$Std.Error
e.coefs21$upCI <- e.coefs21$Estimate + 2*e.coefs21$Std.Error


setwd("C:/Users/Ana/Documents/PhD/First chapter/Path analysis/Results_sp")

pdf(file = "Terax_SH_Y_sp.pdf")

par(mar=c(1,1,1,1))

PlotPath(e.coefs21
         ,cex.text =0.6
         ,cex.text1 = 0.75
         ,offset.poly = 2
         ,significant = 0.05
         ,xlim=c(-20,70)
         ,ylim=c(-30,60)
         ,col.pos="black"
         ,col.neg="red"
         ,col.non.signifi="grey"
         ,Treatment.name= "SHREDDING +\n HERBICIDE"
         ,Species.name="PRESENCE \n LB"
         ,cex.category = 0.5
         ,plot.axis=FALSE
         ,estimate.box.width=c(3, 1),
         cex.estimate = 0.7,
         digits.estimate = 2)
dev.off()

####################################### PICAR #############################################

e <- sp[ which(sp$agri_practice %in% c("C", "S")), ] #Select treatment

e <- e %>% 
  unnest(agri_practice) %>% 
  mutate(new = 1) %>% 
  spread(agri_practice, new, fill = 0) #Create dummy variable for treatment

length(which(e$Zone == "OCCIDENTAL" & e$`S` == "1")) # TREATMENT: 16 p and 88 Control en OCCIDENTAL
length(which(e$Zone == "ORIENTAL" & e$`S` == "1"))   #             15 p+h and 224 Control en ORIENTAL
length(which(e$Zone == "OCCIDENTAL" & e$C == "1")) 
length(which(e$Zone == "ORIENTAL" & e$C == "1")) 


colnames(e)[8] <- "Pres"
colnames(e)[12] <- "Diver"
colnames(e)[13] <- "Heter"
colnames(e)[16] <- "par"
colnames(e)[17] <- "Fallow"
colnames(e)[21] <- "crop_diver"
colnames(e)[25] <- "Treatment"

e$Cover<-scale(e$Cover)
e$Height<-scale(e$Height)
e$biom<-scale(e$biom)
e$Cover_dead<-scale(e$Cover_dead)
e$Heter<-scale(e$Heter)
e$Diver<-scale(e$Diver)
e$tbl<-scale(e$tbl)
e$par<-scale(e$par)
e$Fallow<-scale(e$Fallow)
e$crop_diver<-scale(e$crop_diver)
e$area <- scale(e$area)


#PATH ANALYSIS

# Random intercept Year

e.list2 <- psem( 
  lme( Cover ~ Treatment, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e))

e.fit2 <- summary(e.list2)

# Fill missing paths

e.list21 <- psem( 
  lme( Cover ~ Treatment + par + area, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment + Fallow + par + Cover + tbl, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment + Fallow + tbl + Cover, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment + crop_diver + par + tbl + Cover + Cover_dead + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment + par + area + Cover + Cover_dead, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height + par + tbl + area + Cover_dead + Heter + Diver, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e))

e.fit21 <- summary(e.list21)
x2 <- rsquared(e.list21) # 0.19

e.coefs21 <- coefs(e.list21) 
e.coefs21$lowCI <- e.coefs21$Estimate - 2*e.coefs21$Std.Error
e.coefs21$upCI <- e.coefs21$Estimate + 2*e.coefs21$Std.Error


setwd("C:/Users/Ana/Documents/PhD/First chapter/Path analysis/Results_sp")

pdf(file = "Terax_S_Y_sp.pdf")
par(mar=c(1,1,1,1))

PlotPath(e.coefs21
         ,cex.text =0.6
         ,cex.text1 = 0.75
         ,offset.poly = 2
         ,significant = 0.05
         ,xlim=c(-20,70)
         ,ylim=c(-30,60)
         ,col.pos="black"
         ,col.neg="red"
         ,col.non.signifi="grey"
         ,Treatment.name= "SHREDDING"
         ,Species.name="PRESENCE \n LB"
         ,cex.category = 0.5
         ,plot.axis=FALSE
         ,estimate.box.width=c(3, 1),
         cex.estimate = 0.7,
         digits.estimate = 2)
dev.off()


####################################### LABRAR #############################################

e <- sp[ which(sp$agri_practice %in% c("C", "T")), ] #Select treatment

e <- e %>% 
  unnest(agri_practice) %>% 
  mutate(new = 1) %>% 
  spread(agri_practice, new, fill = 0) #Create dummy variable for treatment

length(which(e$Zone == "OCCIDENTAL" & e$`T` == "1")) # TREATMENT: 65 T and 88 Control en OCCIDENTAL
length(which(e$Zone == "ORIENTAL" & e$`T` == "1"))   #             64 T and 224 Control en ORIENTAL
length(which(e$Zone == "OCCIDENTAL" & e$C == "1")) 
length(which(e$Zone == "ORIENTAL" & e$C == "1")) 


colnames(e)[8] <- "Pres"
colnames(e)[12] <- "Diver"
colnames(e)[13] <- "Heter"
colnames(e)[16] <- "par"
colnames(e)[17] <- "Fallow"
colnames(e)[21] <- "crop_diver"
colnames(e)[25] <- "Treatment"

e$Cover<-scale(e$Cover)
e$Height<-scale(e$Height)
e$biom<-scale(e$biom)
e$Cover_dead<-scale(e$Cover_dead)
e$Heter<-scale(e$Heter)
e$Diver<-scale(e$Diver)
e$tbl<-scale(e$tbl)
e$par<-scale(e$par)
e$Fallow<-scale(e$Fallow)
e$crop_diver<-scale(e$crop_diver)
e$area <- scale(e$area)

#PATH ANALYSIS

# Random intercept Year

e.list2 <- psem( 
  lme( Cover ~ Treatment, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e))

e.fit2 <- summary(e.list2)

# Fill missing paths

e.list21 <- psem( 
  lme( Cover ~ Treatment + par + tbl + area, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment + Fallow + par + area + Cover + tbl, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment + Fallow + Cover + tbl, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment + crop_diver + par + tbl + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment + par + area + Cover + Cover_dead + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height + tbl + area + Heter + par + Cover_dead + Diver, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e))

e.fit21 <- summary(e.list21)
x2 <- rsquared(e.list21) # 0.20 

e.coefs21 <- coefs(e.list21) 
e.coefs21$lowCI <- e.coefs21$Estimate - 2*e.coefs21$Std.Error
e.coefs21$upCI <- e.coefs21$Estimate + 2*e.coefs21$Std.Error


setwd("C:/Users/Ana/Documents/PhD/First chapter/Path analysis/Results_sp")

pdf(file = "Terax_T_Y_sp.pdf")
par(mar=c(1,1,1,1))

PlotPath(e.coefs21
         ,cex.text =0.6
         ,cex.text1 = 0.75
         ,offset.poly = 2
         ,significant = 0.05
         ,xlim=c(-20,70)
         ,ylim=c(-30,60)
         ,col.pos="black"
         ,col.neg="red"
         ,col.non.signifi="grey"
         ,Treatment.name= "TILLAGE"
         ,Species.name="PRESENCE \n LB"
         ,cex.category = 0.5
         ,plot.axis=FALSE
         ,estimate.box.width=c(3, 1),
         cex.estimate = 0.7,
         digits.estimate = 2)
dev.off()

####################################### ALFALFA #############################################

e <- sp[ which(sp$agri_practice %in% c("C", "A")), ] #Select treatment

e <- e %>% 
  unnest(agri_practice) %>% 
  mutate(new = 1) %>% 
  spread(agri_practice, new, fill = 0) #Create dummy variable for treatment

length(which(e$Zone == "OCCIDENTAL" & e$`A` == "1")) # TREATMENT: 0 T and 88 Control en OCCIDENTAL
length(which(e$Zone == "ORIENTAL" & e$`A` == "1"))   #             80 T and 224 Control en ORIENTAL
length(which(e$Zone == "OCCIDENTAL" & e$C == "1")) 
length(which(e$Zone == "ORIENTAL" & e$C == "1")) 

e <- e[-which(e$Zone == "OCCIDENTAL"), ] # Delete oriental because only 0 


colnames(e)[8] <- "Pres"
colnames(e)[12] <- "Diver"
colnames(e)[13] <- "Heter"
colnames(e)[16] <- "par"
colnames(e)[17] <- "Fallow"
colnames(e)[21] <- "crop_diver"
colnames(e)[25] <- "Treatment"

e$Cover<-scale(e$Cover)
e$Height<-scale(e$Height)
e$biom<-scale(e$biom)
e$Cover_dead<-scale(e$Cover_dead)
e$Heter<-scale(e$Heter)
e$Diver<-scale(e$Diver)
e$tbl<-scale(e$tbl)
e$par<-scale(e$par)
e$Fallow<-scale(e$Fallow)
e$crop_diver<-scale(e$crop_diver)
e$area <- scale(e$area)

# Random intercept Year

e.list2 <- psem( 
  lme( Cover ~ Treatment, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e))

e.fit2 <- summary(e.list2)
x2 <- rsquared(e.list2) 

# Fill missing paths

e.list21 <- psem( 
  lme( Cover ~ Treatment + par + area, random =  ~ 1|Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
       data = e, method = 'REML'),
  lme( Cover_dead ~ Treatment + Fallow + par + tbl + Cover, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Height ~ Treatment + Fallow + par + Cover_dead + Diver, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Heter ~ Treatment + par + Cover_dead + Height, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( Diver ~ Treatment + par + area + Cover + Cover_dead + Heter, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  lme( biom ~ Treatment + Fallow + crop_diver + par + tbl + 
         Cover + Height + Cover_dead + Heter + Diver + LAI_sd, 
       correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  lme( LAI_sd ~ Treatment + Cover + Height + par + area + Cover_dead + Heter + Diver, correlation = corGaus(form = ~ Lon_x + Lat_y), random = ~ 1 | Year, data = e, method = 'REML'),
  
  glmmPQL( Pres ~ Treatment + Cover + Height + Cover_dead + Heter + Diver + biom + 
             LAI_sd + Fallow + crop_diver + par + tbl + area,
           random = ~ 1 | Year, correlation = corGaus(form = ~ Lon_x + Lat_y),
           family = "binomial",data = e))

e.fit21 <- summary(e.list21)

x2 <- rsquared(e.list21) #0.24

e.coefs21 <- coefs(e.list21) 
e.coefs21$lowCI <- e.coefs21$Estimate - 2*e.coefs21$Std.Error
e.coefs21$upCI <- e.coefs21$Estimate + 2*e.coefs21$Std.Error


setwd("C:/Users/Ana/Documents/PhD/First chapter/Path analysis/Results_sp")

pdf(file = "Terax_A_Y_sp.pdf")

par(mar=c(1,1,1,1))

PlotPath(e.coefs31
         ,cex.text =0.6
         ,cex.text1 = 0.75
         ,offset.poly = 2
         ,significant = 0.05
         ,xlim=c(-20,70)
         ,ylim=c(-30,60)
         ,col.pos="black"
         ,col.neg="red"
         ,col.non.signifi="grey"
         ,Treatment.name= "ALFALFA"
         ,Species.name="PRESENCE \n LB"
         ,cex.category = 0.5
         ,plot.axis=FALSE
         ,estimate.box.width=c(3, 1),
         cex.estimate = 0.7,
         digits.estimate = 2)
dev.off()
