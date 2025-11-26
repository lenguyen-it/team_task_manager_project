import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:task_team_frontend_mobile/config/env.dart';

import 'package:task_team_frontend_mobile/providers/activitylog_provider.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/conversation_provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/providers/message_provider.dart';
import 'package:task_team_frontend_mobile/providers/notification_provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';
import 'package:task_team_frontend_mobile/providers/role_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/providers/tasktype_provider.dart';

import 'package:task_team_frontend_mobile/screens/login_screen.dart';

Future<void> main() async {
  await dotenv.load();
  // runApp(const MyApp());
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

final socketUrl = (Env.localUrl.isNotEmpty) ? Env.localUrl : Env.baseUrl;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => RoleProvider()),
        ChangeNotifierProvider(create: (context) => ProjectProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => TasktypeProvider()),
        ChangeNotifierProvider(create: (context) => EmployeeProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => ActivitylogProvider()),
        Provider<IO.Socket>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            final token = auth.token;

            final socket = IO.io(
              socketUrl,
              IO.OptionBuilder()
                  .setTransports(['websocket'])
                  .disableAutoConnect()
                  .setExtraHeaders({'Authorization': 'Bearer $token'})
                  .setAuth({'token': token})
                  .build(),
            );

            socket.connect();

            // Debug log
            socket
                .onConnect((_) => debugPrint('Socket connected: ${socket.id}'));
            socket.onConnectError(
                (err) => debugPrint('Socket connect error: $err'));
            socket.onError((err) => debugPrint('Socket error: $err'));
            socket.onDisconnect((_) => debugPrint('Socket disconnected'));

            return socket;
          },
          dispose: (context, socket) => socket.disconnect(),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, IO.Socket,
            ConversationProvider>(
          create: (context) => ConversationProvider(
            currentEmployeeId: '',
            token: '',
            socket: Provider.of<IO.Socket>(context, listen: false),
          ),
          update: (context, auth, socket, previous) {
            // Nếu chưa đăng nhập
            if (auth.currentEmployee == null || auth.token == null) {
              previous?.clearAll();
              return previous ??
                  ConversationProvider(
                    currentEmployeeId: '',
                    token: '',
                    socket: socket,
                  );
            }

            final newEmployeeId = auth.currentEmployee!.employeeId;
            final newToken = auth.token!;

            if (previous == null ||
                previous.token != newToken ||
                previous.currentEmployeeId != newEmployeeId) {
              final provider = ConversationProvider(
                currentEmployeeId: newEmployeeId,
                token: newToken,
                socket: socket,
              );

              provider.loadConversations(refresh: true);

              return provider;
            }

            // Cập nhật socket nếu cần
            if (previous.socket != socket) {
              previous.socket = socket;
            }

            return previous;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, IO.Socket, MessageProvider>(
          create: (context) => MessageProvider(
            currentEmployeeId: '',
            token: '',
            socket: Provider.of<IO.Socket>(context, listen: false),
          ),
          update: (context, auth, socket, previous) {
            if (auth.currentEmployee == null || auth.token == null) {
              return previous ??
                  MessageProvider(
                    currentEmployeeId: '',
                    token: '',
                    socket: socket,
                  );
            }

            final newEmployeeId = auth.currentEmployee!.employeeId;
            final newToken = auth.token!;

            if (previous == null ||
                previous.token != newToken ||
                previous.currentEmployeeId != newEmployeeId) {
              return MessageProvider(
                currentEmployeeId: newEmployeeId,
                token: newToken,
                socket: socket,
              );
            }

            previous.socket = socket;
            return previous;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Team Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
