# Verificacion PERTENENCIA vs PERTENENCIA2
Fecha: 2026-09-20 16:56 

Tiempo de carga: 1.9 min
Clase: data.table 
Dim: 20,957,004 x 29 

## NA y distribucion por columna

### PERTENENCIA ( integer )
NA: 104,326 (0.50%)
PERTENENCIA
       0        1     <NA> 
17735100  3117578   104326 

### PERTENENCIA2 ( numeric )
NA: 0 (0.00%)
PERTENENCIA2
       0        1 
17839426  3117578 

### PUEBLO_ORIGINARIO_BIN ( numeric )
NA: 0 (0.00%)
PUEBLO_ORIGINARIO_BIN
       0        1 
19177041  1779963 

### CONADI ( integer )
NA: 19,221,640 (91.72%)
CONADI
       0        1     <NA> 
  848747   886617 19221640 

### RSH ( integer )
NA: 19,221,640 (91.72%)
RSH
       0        1     <NA> 
  363994  1371370 19221640 

## Tabla cruzada PERTENENCIA x PERTENENCIA2

           PERTENENCIA2
PERTENENCIA        0        1
       0    17735100        0
       1           0  3117578
       <NA>   104326        0

## Cruce de fuentes cuando PERTENENCIA es NA

Filas con PERTENENCIA NA: 104,326 
De ellas, PERTENENCIA2 = 1: 0 
De ellas, PERTENENCIA2 = 0: 104,326 
De ellas, PERTENENCIA2 = NA: 0 
