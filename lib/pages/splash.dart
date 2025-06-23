import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notehub/pages/intro/get_started.dart';
import 'package:notehub/theames/app_color.dart';

class SplashPage extends StatefulWidget{
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState(){
    super.initState();
    redirect();
  }
  
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Text("NoteHUB",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: AppColors.primary),),
      ),
    );
  }
  
  Future<void> redirect() async{
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (BuildContext context)=> GetStartedPage())
    );
  }
}