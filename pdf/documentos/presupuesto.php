<?php
	/*-------------------------
	Autor: Wellmar Carvajal Mendez
	Web: systemswell.com
	Mail: soporte@systemswell.com
	---------------------------*/
	 ob_start();
	session_start();
	/* Connect To Database*/
	include("../../config/db.php");
	include("../../config/conexion.php");
	$session_id= session_id();
	$sql_count=mysqli_query($con,"select * from tmp ");
	$count=mysqli_num_rows($sql_count);
	if ($count==0)
	{
	echo "<script>alert('No hay productos agregados al presupuesto')</script>";
	echo "<script>window.close();</script>";
	exit;
	}

	require_once(dirname(__FILE__).'/../html2pdf.class.php');
		
	//Variables por GET
	$cliente=intval($_GET['cliente']);
	$descripcion=mysqli_real_escape_string($con,(strip_tags($_REQUEST['descripcion'], ENT_QUOTES)));
	

	//Fin de variables por GET
	$sql=mysqli_query($con, "select LAST_INSERT_ID(id) as last from presupuestos order by id desc limit 0,1 ");
	$rw=mysqli_fetch_array($sql);
	$numero = (isset($rw['last'])) ? $rw['last'] + 1 : 1;
	$perfil=mysqli_query($con,"select * from perfil limit 0,1");//Obtengo los datos de la emprea
	$rw_perfil=mysqli_fetch_array($perfil);
	if (!$rw_perfil) $rw_perfil = array();
	
	$sql_cliente=mysqli_query($con,"select * from clientes where id='$cliente' limit 0,1");//Obtengo los datos del proveedor
	$rw_cliente=mysqli_fetch_array($sql_cliente);
	if (!$rw_cliente) $rw_cliente = array();
    // get the HTML
     ob_clean();
     include(__DIR__.'/res/presupuesto_html.php');
    $content = ob_get_clean();

    try
    {
		$archivo='Presupuesto.pdf';

        // init HTML2PDF
        $html2pdf = new HTML2PDF('P', 'LETTER', 'es', true, 'UTF-8', array(0, 0, 0, 0));
        // display the full page
        $html2pdf->pdf->SetDisplayMode('fullpage');
        // convert
        $html2pdf->writeHTML($content, isset($_GET['vuehtml']));
        // send the PDF
        $html2pdf->Output($archivo, 'I'); 
 
    }
    catch(HTML2PDF_exception $e) {
        echo $e;
        exit;
    }

/*
//enviar por mail
    // generando el pdf
    require 'phpmailer/PHPMailerAutoload.php';
    $correo = 'digitalmarketingxxx@gmail.com';
    $enviocliente=$rw['email'];
   
    //we need to create an instance of PHPMailer
    $mail = new PHPMailer();
    //set where we are sending email
    $mail->addAddress($correo,'Cotización');
    //set who is sending an email
    $mail->setFrom($correo,$enviocliente,'Softwell');
    //set subject
    $mail->Subject = "Cotizacion Softwell";
    //type of email
    $mail->isHTML(true);
    //write email
    $mail->Body = "<p>Adjunto presupuesto</p><br><br><a href='http://google.com'>Realizar pagos</a>";
    //include attachment
    $mail->addAttachment($archivo);
    //send an email
    $mail->Send();
*/
?>
