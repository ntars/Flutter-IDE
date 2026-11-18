// fide_starter 模板入口。
//
// 这个模板就是「删掉 IDE 之后还能 flutter run」的样板：lib/generated/ 下的
// 代码由 Fide 生成，删掉 IDE 或删掉整个 design/ 目录，本项目照样构建——
// design/ 里的 intent / delta 是生成输入，不是运行时依赖。
//
// 这里刻意直接 import flutter/material，不收拢单一出口：模板是**用户项目**
// 的起点，要长成用户习惯的样子。deprecated 提示在这份文件里豁免——
// 模板不该替用户做 UI 库选型。
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

void main() => runApp(const StarterApp());

class StarterApp extends StatelessWidget {
  const StarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fide_starter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C1F28)),
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '欢迎回来',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text(
                '上次登录 3 天前',
                style: TextStyle(fontSize: 13, color: Color(0x73000000)),
              ),
              SizedBox(height: 24),
              FilledButton(onPressed: null, child: Text('继续')),
            ],
          ),
        ),
      ),
    );
  }
}
