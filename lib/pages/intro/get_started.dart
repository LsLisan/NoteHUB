import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notehub/assets/app_images.dart';
import 'package:notehub/assets/basic_app_button.dart';
import 'package:notehub/pages/intro/choose_mode.dart';
import 'package:notehub/theames/app_color.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.logo),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0), // You can adjust the padding as needed
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20,),
                      Center(
                        child: Text(
                          "Welcome",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text("Share your precious notes with others",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                  SizedBox(height: 8,),
                  BasicAppButton(onPressed: (){
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (BuildContext context)=> ChooseModePage())
                      );
                    }, title: "Get Started"
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
