library(DescTools)

x <- c(50, 60, 70, 80, 90)
y <- c(52, 58, 72, 78, 88)

resultado <- CCC(x, y, ci = "z-transform", conf.level = 0.95)

cat("Estructura del objeto:\n")
str(resultado)

cat("\n\nNombres del objeto:\n")
print(names(resultado))

cat("\n\nClase del objeto:\n")
print(class(resultado))
