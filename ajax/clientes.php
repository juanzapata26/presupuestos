<?php

require_once ("../config/db.php");//Contiene las variables de configuracion para conectar a la base de datos
require_once ("../config/conexion.php");//Contiene funcion que conecta a la base de datos
    
$nombre=$_POST['nombre'];
$telefono=$_POST['telefono'];
$email=$_POST['email'];
$direccion=$_POST['direccion'];
$sql="INSERT INTO `clientes` (`id`, `nombre`, `telefono`, `email`, `direccion`) VALUES (NULL, '$nombre', '$telefono', '$email', '$direccion');";
$insert=mysqli_query($con,$sql);
?>