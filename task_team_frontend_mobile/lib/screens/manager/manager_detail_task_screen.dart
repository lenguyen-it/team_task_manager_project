import 'package:flutter/material.dart';

import '../../models/task_model.dart';

class ManagerDetailTaskScreen extends StatefulWidget {
  final TaskModel task;

  const ManagerDetailTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<ManagerDetailTaskScreen> createState() =>
      _ManagerDetailTaskScreenState();
}

class _ManagerDetailTaskScreenState extends State<ManagerDetailTaskScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox.expand(),
    );
  }
}
