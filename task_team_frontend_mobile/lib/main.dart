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

        // FIX: Tạo Socket wrapper
        ProxyProvider<AuthProvider, _SocketWrapper?>(
          create: (context) => null,
          update: (context, auth, previousWrapper) {
            final currentToken = auth.token;

            // Nếu chưa có token, không tạo socket
            if (currentToken == null || currentToken.isEmpty) {
              previousWrapper?.dispose();
              return null;
            }

            // Token thay đổi → tạo socket mới
            if (previousWrapper?.token != currentToken) {
              debugPrint('🔌 Creating new socket with token');
              previousWrapper?.dispose();
              return _SocketWrapper(currentToken);
            }

            return previousWrapper;
          },
          dispose: (context, wrapper) => wrapper?.dispose(),
        ),

        // Provide Socket từ wrapper
        ProxyProvider<_SocketWrapper?, IO.Socket?>(
          update: (context, wrapper, _) => wrapper?.socket,
        ),

        // FIX: ConversationProvider với dependencies đúng
        ChangeNotifierProxyProvider2<AuthProvider, _SocketWrapper?,
            ConversationProvider>(
          create: (context) => ConversationProvider(
            currentEmployeeId: '',
            token: '',
            socket: null,
          ),
          update: (context, auth, wrapper, previous) {
            final currentEmployeeId = auth.currentEmployee?.employeeId ?? '';
            final token = auth.token ?? '';
            final socket = wrapper?.socket;

            // Nếu chưa có provider, tạo mới
            if (previous == null) {
              debugPrint(
                  '🎬 Creating ConversationProvider: employee=$currentEmployeeId');
              return ConversationProvider(
                currentEmployeeId: currentEmployeeId,
                token: token,
                socket: socket != null && socket.connected ? socket : null,
              );
            }

            // Kiểm tra xem có thay đổi không
            final employeeChanged =
                previous.currentEmployeeId != currentEmployeeId;
            final tokenChanged = previous.token != token;
            final socketChanged = previous.socket != socket;

            if (employeeChanged || tokenChanged || socketChanged) {
              debugPrint(
                  '🔄 Updating ConversationProvider: employee=$currentEmployeeId, token=${token.isNotEmpty}, socket=${socket?.connected}');
            }

            // Cập nhật thông tin
            previous.currentEmployeeId = currentEmployeeId;
            previous.token = token;

            // FIX: Chỉ update socket khi connected
            if (socket != null && socket.connected) {
              if (previous.socket != socket) {
                previous.updateSocket(socket);
              }
            } else {
              previous.socket = null;
            }

            // Nếu vừa đăng nhập (có employee và token), load conversations
            if (currentEmployeeId.isNotEmpty &&
                token.isNotEmpty &&
                employeeChanged) {
              debugPrint('✅ User logged in, loading conversations...');
              Future.microtask(() {
                previous.loadConversations(refresh: true);
              });
            }

            // Nếu đăng xuất, clear data
            if (currentEmployeeId.isEmpty &&
                previous.conversations.isNotEmpty) {
              debugPrint('🔴 User logged out, clearing conversations');
              previous.clearAll();
            }

            return previous;
          },
        ),

        // FIX: MessageProvider với dependencies đúng
        ChangeNotifierProxyProvider2<AuthProvider, _SocketWrapper?,
            MessageProvider>(
          create: (context) => MessageProvider(
            currentEmployeeId: '',
            token: '',
            socket: null,
          ),
          update: (context, auth, wrapper, previous) {
            final currentEmployeeId = auth.currentEmployee?.employeeId ?? '';
            final token = auth.token ?? '';
            final socket = wrapper?.socket;

            if (previous == null) {
              debugPrint(
                  '🎬 Creating MessageProvider: employee=$currentEmployeeId');
              return MessageProvider(
                currentEmployeeId: currentEmployeeId,
                token: token,
                socket: socket != null && socket.connected ? socket : null,
              );
            }

            // Cập nhật thông tin
            previous.currentEmployeeId = currentEmployeeId;
            previous.token = token;

            // FIX: Chỉ update socket khi connected
            if (socket != null && socket.connected) {
              if (previous.socket != socket) {
                previous.updateSocket(socket);
              }
            } else {
              previous.socket = null;
            }

            // Clear messages khi đăng xuất
            if (currentEmployeeId.isEmpty && previous.messages.isNotEmpty) {
              debugPrint('🔴 User logged out, clearing messages');
              previous.clearMessages();
            }

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

// Wrapper class để track token với socket
class _SocketWrapper {
  final String? token;
  final IO.Socket socket;

  _SocketWrapper(this.token) : socket = _createSocketInstance(token);

  static IO.Socket _createSocketInstance(String? token) {
    final socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders(token != null && token.isNotEmpty
              ? {'Authorization': 'Bearer $token'}
              : {})
          .setAuth(token != null && token.isNotEmpty ? {'token': token} : {})
          .build(),
    );

    if (token != null && token.isNotEmpty) {
      socket.connect();

      socket.on('connect', (_) {
        debugPrint('✅ Socket Connected! ID: ${socket.id}');
        debugPrint('🔑 Auth sent: ${socket.auth}');
      });

      socket
          .onConnectError((err) => debugPrint('❌ Socket connect error: $err'));
      socket.onError((err) => debugPrint('❌ Socket error: $err'));
      socket.onDisconnect((_) => debugPrint('🔌 Socket disconnected'));
    } else {
      debugPrint('⚠️ No token, socket not connected');
    }

    return socket;
  }

  void dispose() {
    debugPrint('🔌 Disposing socket...');
    socket.disconnect();
    socket.dispose();
  }
}
