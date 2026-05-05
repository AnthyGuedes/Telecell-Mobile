import 'package:flutter/material.dart';
import 'screens/cadastro_page.dart'; 
import 'screens/listar_page.dart'; 

void main() {
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Clientes',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(primarySwatch: Colors.blue), 
      // Define qual tela abre primeiro (A de cadastro)
      initialRoute: '/',
      routes: {
        '/': (context) => CadastroPage(), 
        '/listar': (context) => ListarPage(), 
      },
    );
  }
}