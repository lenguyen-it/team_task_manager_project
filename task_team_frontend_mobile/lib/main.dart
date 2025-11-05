import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';

import 'package:task_team_frontend_mobile/providers/role_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/providers/tasktype_provider.dart';
import 'package:task_team_frontend_mobile/screens/employee_screen.dart';
import 'package:task_team_frontend_mobile/screens/project_screen.dart';
import 'package:task_team_frontend_mobile/screens/role_screen.dart';
import 'package:task_team_frontend_mobile/screens/task_screen.dart';
import 'package:task_team_frontend_mobile/screens/tasktype_screen.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RoleProvider()),
        ChangeNotifierProvider(create: (context) => ProjectProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => TasktypeProvider()),
        ChangeNotifierProvider(create: (context) => EmployeeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Team Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const RoleScreen(),
        // const ProjectScreen(),
        // const TaskScreen(),
        // const TasktypeScreen(),
        // const EmployeeScreen(),
      ),
    );
  }
}
