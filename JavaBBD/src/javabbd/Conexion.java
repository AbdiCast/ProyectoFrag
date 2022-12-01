/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package ProyectoBd;

import java.sql.Connection;
import java.sql.Statement; 
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.*;

/**
 *
 * @author Abdi y Ceja
 */
public class Conexion {
    public static Connection getConnection() // esta método es para conectar "metodo conectar"
    {
       String conexionURL = "jdbc:sqlserver://bddsl1.database.windows.net:1433;database=AWBDD;user=SA_BDD@bddsl1;password={your_password_here};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;";
       try
       {
        Connection conexion = DriverManager.getConnection(conexionURL);   
         return conexion; 
       }catch(SQLException ex){
           System.out.println(ex.toString());
           return null;
       }  
    }
}
