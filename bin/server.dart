import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';

// Configurações globais
const String jwtSecret = 'safeedu_secret_key_2025';
const Duration tokenDuration = Duration(hours: 24);

// Helper para resposta JSON
Response jsonResponse(Map<String, dynamic> data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
    },
  );
}

// Banco de dados simulado em memória
class Database {
  // Hash de senhas usando SHA-256
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Usuários de teste
  static final Map<String, User> users = {
    'fred@fred.com': User(
      id: '1',
      email: 'fred@fred.com',
      password: _hashPassword('fred123'),
      name: 'Frederico',
    ),
    'julia@safeedu.com': User(
      id: '2',
      email: 'julia@safeedu.com',
      password: _hashPassword('julia123'),
      name: 'Júlia',
    ),
  };

  // Escolas com coordenadas reais de Fortaleza/CE
  static final List<School> schools = [
    School(
      id: '1',
      name: 'Escola A',
      rating: 4,
      latitude: -3.7319,
      longitude: -38.5267,
      imageUrl: 'https://picsum.photos/400/300?random=1',
    ),
    School(
      id: '2',
      name: 'Escola B',
      rating: 3,
      latitude: -3.7419,
      longitude: -38.5367,
      imageUrl: 'https://picsum.photos/400/300?random=2',
    ),
    School(
      id: '3',
      name: 'Escola C',
      rating: 3,
      latitude: -3.7219,
      longitude: -38.5167,
      imageUrl: 'https://picsum.photos/400/300?random=3',
    ),
    School(
      id: '4',
      name: 'Escola D',
      rating: 4,
      latitude: -3.7519,
      longitude: -38.5467,
      imageUrl: 'https://picsum.photos/400/300?random=4',
    ),
    School(
      id: '5',
      name: 'Escola E',
      rating: 4,
      latitude: -3.7119,
      longitude: -38.5067,
      imageUrl: 'https://picsum.photos/400/300?random=5',
    ),
  ];

  // Comentários pré-populados
  static final List<Comment> comments = [
    Comment(
      id: '1',
      schoolId: '1',
      userId: '1',
      userName: 'Frederico',
      comment: 'Excelente escola! Meus filhos adoram estudar aqui.',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Comment(
      id: '2',
      schoolId: '1',
      userId: '2',
      userName: 'Júlia',
      comment: 'Ótima infraestrutura e professores dedicados.',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Comment(
      id: '3',
      schoolId: '2',
      userId: '1',
      userName: 'Frederico',
      comment: 'Boa escola, mas poderia melhorar a comunicação.',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    Comment(
      id: '4',
      schoolId: '3',
      userId: '2',
      userName: 'Júlia',
      comment: 'Ambiente acolhedor e seguro para as crianças.',
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
  ];

  // Log de prints enviados
  static final List<PrintLog> prints = [];
}

// Modelos de dados
class User {
  final String id;
  final String email;
  final String password;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
      };
}

class School {
  final String id;
  final String name;
  final int rating;
  final double latitude;
  final double longitude;
  final String imageUrl;

  School({
    required this.id,
    required this.name,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
      };
}

class Comment {
  final String id;
  final String schoolId;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;
  final String? parentId;

  Comment({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'user_id': userId,
        'user_name': userName,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
        'parent_id': parentId,
      };
}

class PrintLog {
  final String id;
  final String userId;
  final String fileName;
  final DateTime createdAt;

  PrintLog({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'file_name': fileName,
        'created_at': createdAt.toIso8601String(),
      };
}

// Utilitários para JWT
class JWTUtils {
  static String generateToken(User user) {
    final jwt = JWT({
      'sub': user.id,
      'email': user.email,
      'name': user.name,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(tokenDuration).millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(jwtSecret));
  }

  static Map<String, dynamic>? validateToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload;
      
      // Verificar se o token não expirou
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (now > exp) {
        return null; // Token expirado
      }
      
      return payload;
    } catch (e) {
      return null; // Token inválido
    }
  }
}

// Middleware de autenticação
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Pular autenticação para endpoints específicos
      final skipAuth = [
        'generate_token',
        'validate_token',
        'motd',
        'health',
        'debug',
        'OPTIONS'
      ];
      
      final shouldSkip = skipAuth.any((path) => 
        request.url.path.contains(path) || request.method == 'OPTIONS');
      
      if (shouldSkip) {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return jsonResponse(
          {
            'error': 'Token de acesso requerido',
            'message': 'Forneça um token válido no header Authorization: Bearer <token>'
          },
          status: 401,
        );
      }

      final token = authHeader.substring(7);
      final payload = JWTUtils.validateToken(token);
      
      if (payload == null) {
        return jsonResponse(
          {
            'error': 'Token inválido ou expirado',
            'message': 'Faça login novamente para obter um token válido'
          },
          status: 401,
        );
      }

      // Adicionar informações do usuário ao request
      final updatedRequest = request.change(context: {
        'user': payload,
      });

      return innerHandler(updatedRequest);
    };
  };
}

// Parser para multipart/form-data simplificado
class MultipartParser {
  static Future<Map<String, dynamic>> parse(Request request) async {
    final contentType = request.headers['content-type'];
    if (contentType == null || !contentType.startsWith('multipart/form-data')) {
      throw Exception('Content-Type deve ser multipart/form-data');
    }

    // Extrair boundary
    final boundary = contentType.split('boundary=')[1];
    final body = await request.readAsString();
    
    final parts = <String, dynamic>{};
    final sections = body.split('--$boundary');
    
    for (final section in sections) {
      if (section.trim().isEmpty || section.contains('--')) continue;
      
      final lines = section.split('\r\n');
      String? name;
      List<int>? fileBytes;
      String? textValue;
      
      // Parse headers
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('Content-Disposition')) {
          final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(line);
          if (nameMatch != null) {
            name = nameMatch.group(1);
          }
        }
        
        // Encontrar linha vazia (separador header/content)
        if (line.trim().isEmpty && i < lines.length - 1) {
          final content = lines.sublist(i + 1).join('\r\n').trim();
          
          if (content.isNotEmpty) {
            if (line.contains('filename=')) {
              // É um arquivo
              fileBytes = content.codeUnits;
            } else {
              // É texto
              textValue = content;
            }
          }
          break;
        }
      }
      
      if (name != null) {
        if (fileBytes != null) {
          parts[name] = {'type': 'file', 'data': fileBytes};
        } else if (textValue != null) {
          parts[name] = {'type': 'text', 'data': textValue};
        }
      }
    }
    
    return parts;
  }
}

// Classe principal da API
class SafeEduAPI {
  final Router router = Router();

  SafeEduAPI() {
    _setupRoutes();
  }

  void _setupRoutes() {
    // Endpoint #01 - Gerar token JWT
    router.post('/jwt/generate_token', _generateToken);
    
    // Endpoint #02 - Validar token JWT
    router.post('/jwt/validate_token', _validateToken);
    
    // Endpoint #03 - MOTD (Message of the Day)
    router.get('/A2/motd', _getMotd);
    
    // Endpoint #04 - Lista de escolas
    router.get('/A2/school_list', _getSchoolList);
    
    // Endpoint #05 - Comentários
    router.get('/A2/comments', _getComments);
    router.post('/A2/comments', _postComment);
    
    // Endpoint #06 - Prints
    router.get('/A2/prints', _getPrints);
    router.post('/A2/prints', _postPrint);

    // Rota para servir arquivos estáticos
    router.get('/uploads/<fileName>', _getUploadedFile);
    
    // Health check
    router.get('/health', _healthCheck);
    
    // Debug: Lista todas as rotas disponíveis
    router.get('/debug/routes', _debugRoutes);
  }

  // Endpoint #01 - Autenticação
  Future<Response> _generateToken(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final email = data['email'] as String?;
      final password = data['password'] as String?;
      
      if (email == null || password == null) {
        return jsonResponse(
          {
            'error': 'Email e senha são obrigatórios',
            'message': 'Forneça email e password no body da requisição'
          },
          status: 400,
        );
      }

      // Validar formato do email
      if (!_isValidEmail(email)) {
        return jsonResponse(
          {
            'error': 'Email inválido',
            'message': 'Forneça um email válido com @ e pelo menos um ponto'
          },
          status: 400,
        );
      }

      // Validar senha
      if (!_isValidPassword(password)) {
        return jsonResponse(
          {
            'error': 'Senha inválida',
            'message': 'A senha deve ter pelo menos 6 caracteres com letras e números'
          },
          status: 400,
        );
      }

      final user = Database.users[email];
      if (user == null) {
        return jsonResponse(
          {
            'error': 'Usuário não encontrado',
            'message': 'Email não cadastrado no sistema'
          },
          status: 401,
        );
      }

      final hashedPassword = Database._hashPassword(password);
      if (user.password != hashedPassword) {
        return jsonResponse(
          {
            'error': 'Senha incorreta',
            'message': 'A senha fornecida não confere'
          },
          status: 401,
        );
      }

      final token = JWTUtils.generateToken(user);
      
      return jsonResponse({
        'success': true,
        'token': token,
        'user': user.toJson(),
        'expires_in': tokenDuration.inSeconds,
        'message': 'Login realizado com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro interno do servidor',
          'message': 'Erro ao processar requisição: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #02 - Validar token
  Future<Response> _validateToken(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final token = data['token'] as String?;
      if (token == null) {
        return jsonResponse(
          {
            'error': 'Token é obrigatório',
            'message': 'Forneça o token no campo "token"'
          },
          status: 400,
        );
      }

      final payload = JWTUtils.validateToken(token);
      if (payload == null) {
        return jsonResponse({
          'valid': false,
          'error': 'Token inválido ou expirado',
          'message': 'O token fornecido não é válido ou já expirou'
        });
      }

      return jsonResponse({
        'valid': true,
        'user': {
          'id': payload['sub'],
          'email': payload['email'],
          'name': payload['name'],
        },
        'expires_at': DateTime.fromMillisecondsSinceEpoch(
          (payload['exp'] as int) * 1000
        ).toIso8601String(),
        'message': 'Token válido'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro interno do servidor',
          'message': 'Erro ao validar token: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #03 - Mensagem do dia
  Future<Response> _getMotd(Request request) async {
    final messages = [
      'Bem-vindo ao SafeEdu! Sua segurança é nossa prioridade.',
      'Explore as melhores escolas da sua região com total segurança.',
      'Mantenha-se seguro e bem informado com o SafeEdu.',
      'Conectando famílias a escolas seguras e de qualidade.',
      'Sua jornada educacional segura começa aqui no SafeEdu.',
      'Educação de qualidade e segurança caminham juntas.',
      'Descubra escolas que priorizam o bem-estar dos estudantes.',
      'SafeEdu: onde a segurança encontra a excelência educacional.',
    ];
    
    final random = Random();
    final selectedMessage = messages[random.nextInt(messages.length)];
    
    return jsonResponse({
      'message': selectedMessage,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0'
    });
  }

  // Endpoint #04 - Lista de escolas
  Future<Response> _getSchoolList(Request request) async {
    try {
      // Ordenar escolas alfabeticamente conforme especificação
      final sortedSchools = List<School>.from(Database.schools)
        ..sort((a, b) => a.name.compareTo(b.name));
      
      return jsonResponse({
        'success': true,
        'schools': sortedSchools.map((school) => school.toJson()).toList(),
        'total': sortedSchools.length,
        'message': 'Lista de escolas obtida com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao buscar escolas',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #05 - Obter comentários
  Future<Response> _getComments(Request request) async {
    try {
      final schoolId = request.url.queryParameters['school_id'];
      
      List<Comment> filteredComments = Database.comments;
      if (schoolId != null && schoolId.isNotEmpty) {
        filteredComments = Database.comments
            .where((comment) => comment.schoolId == schoolId)
            .toList();
      }
      
      // Ordenar por data de criação (mais recentes primeiro)
      filteredComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return jsonResponse({
        'success': true,
        'comments': filteredComments.map((comment) => comment.toJson()).toList(),
        'total': filteredComments.length,
        'school_id': schoolId,
        'message': 'Comentários obtidos com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao buscar comentários',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #05 - Adicionar comentário
  Future<Response> _postComment(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final user = request.context['user'] as Map<String, dynamic>;
      
      final schoolId = data['id_escola'] as String?;
      final commentText = data['comentario'] as String?;
      final parentId = data['parent_id'] as String?;
      
      if (schoolId == null || commentText == null || commentText.trim().isEmpty) {
        return jsonResponse(
          {
            'error': 'Dados obrigatórios ausentes',
            'message': 'id_escola e comentario são obrigatórios'
          },
          status: 400,
        );
      }

      // Verificar se a escola existe
      final schoolExists = Database.schools.any((s) => s.id == schoolId);
      if (!schoolExists) {
        return jsonResponse(
          {
            'error': 'Escola não encontrada',
            'message': 'ID da escola fornecido não existe'
          },
          status: 404,
        );
      }

      // Verificar comentário pai se fornecido
      if (parentId != null) {
        final parentExists = Database.comments.any((c) => c.id == parentId);
        if (!parentExists) {
          return jsonResponse(
            {
              'error': 'Comentário pai não encontrado',
              'message': 'parent_id fornecido não existe'
            },
            status: 404,
          );
        }
      }

      final newComment = Comment(
        id: (Database.comments.length + 1).toString(),
        schoolId: schoolId,
        userId: user['sub'],
        userName: user['name'],
        comment: commentText.trim(),
        createdAt: DateTime.now(),
        parentId: parentId,
      );

      Database.comments.add(newComment);
      
      return jsonResponse({
        'success': true,
        'message': 'Comentário adicionado com sucesso',
        'comment': newComment.toJson(),
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao adicionar comentário',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #06 - Listar prints
  Future<Response> _getPrints(Request request) async {
    try {
      final user = request.context['user'] as Map<String, dynamic>?;
      final userId = request.url.queryParameters['user_id'] ?? user?['sub'];
      
      List<PrintLog> filteredPrints = Database.prints;
      if (userId != null) {
        filteredPrints = Database.prints
            .where((print) => print.userId == userId)
            .toList();
      }
      
      // Ordenar por data (mais recentes primeiro)
      filteredPrints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return jsonResponse({
        'success': true,
        'prints': filteredPrints.map((print) => print.toJson()).toList(),
        'total': filteredPrints.length,
        'message': 'Lista de prints obtida com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao listar prints',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #06 - Upload de print
  Future<Response> _postPrint(Request request) async {
    try {
      final contentType = request.headers['content-type'];
      final user = request.context['user'] as Map<String, dynamic>;
      
      // Aceitar tanto JSON quanto multipart
      if (contentType != null && contentType.contains('application/json')) {
        // Modo JSON (simulado)
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final userId = data['id_user'] as String?;
        
        if (userId == null) {
          return jsonResponse(
            {
              'error': 'Dados obrigatórios ausentes',
              'message': 'id_user é obrigatório'
            },
            status: 400,
          );
        }
        
        // Criar diretório uploads se não existir
        final uploadsDir = Directory('uploads');
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }
        
        // Simular arquivo
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'print_simulado_$timestamp.png';
        
        // Criar arquivo de exemplo
        final file = File('uploads/$fileName');
        await file.writeAsString('Print simulado via JSON - ${DateTime.now()}');

        final printLog = PrintLog(
          id: (Database.prints.length + 1).toString(),
          userId: userId,
          fileName: fileName,
          createdAt: DateTime.now(),
        );

        Database.prints.add(printLog);
        
        return jsonResponse({
          'success': true,
          'message': 'Print simulado enviado com sucesso',
          'print': printLog.toJson(),
          'file_url': '/uploads/$fileName',
          'mode': 'JSON simulado'
        });
        
      } else if (contentType != null && contentType.contains('multipart/form-data')) {
        // Modo multipart (simplificado)
        
        // Criar diretório uploads se não existir
        final uploadsDir = Directory('uploads');
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }
        
        // Simular processamento do multipart
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'print_multipart_$timestamp.png';
        
        // Criar arquivo de exemplo
        final file = File('uploads/$fileName');
        await file.writeAsString('Print via multipart - ${DateTime.now()}');

        final printLog = PrintLog(
          id: (Database.prints.length + 1).toString(),
          userId: user['sub'],
          fileName: fileName,
          createdAt: DateTime.now(),
        );

        Database.prints.add(printLog);
        
        return jsonResponse({
          'success': true,
          'message': 'Print multipart simulado enviado com sucesso',
          'print': printLog.toJson(),
          'file_url': '/uploads/$fileName',
          'mode': 'Multipart simulado'
        });
        
      } else {
        return jsonResponse(
          {
            'error': 'Formato inválido',
            'message': 'Use Content-Type: application/json ou multipart/form-data'
          },
          status: 400,
        );
      }
      
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao processar upload',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Servir arquivos estáticos
  Future<Response> _getUploadedFile(Request request, String fileName) async {
    try {
      final file = File('uploads/$fileName');
      if (!await file.exists()) {
        return jsonResponse(
          {
            'error': 'Arquivo não encontrado',
            'message': 'O arquivo solicitado não existe'
          },
          status: 404,
        );
      }

      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      return Response.ok(
        bytes,
        headers: {
          'Content-Type': mimeType,
          'Content-Length': bytes.length.toString(),
          'Cache-Control': 'public, max-age=86400', // Cache por 24h
        },
      );
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao servir arquivo',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Health check
  Future<Response> _healthCheck(Request request) async {
    return jsonResponse({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'uptime': DateTime.now().millisecondsSinceEpoch,
      'endpoints': {
        'auth': '/jwt/generate_token',
        'schools': '/A2/school_list',
        'comments': '/A2/comments',
        'prints': '/A2/prints'
      }
    });
  }

  // Debug: Listar rotas disponíveis
  Future<Response> _debugRoutes(Request request) async {
    return jsonResponse({
      'available_routes': [
        'POST /jwt/generate_token - Autenticação',
        'POST /jwt/validate_token - Validar token',
        'GET  /A2/motd - Mensagem do dia',
        'GET  /A2/school_list - Lista de escolas',
        'GET  /A2/comments - Comentários',
        'POST /A2/comments - Adicionar comentário',
        'GET  /A2/prints - Lista de prints',
        'POST /A2/prints - Upload de print',
        'GET  /uploads/<fileName> - Arquivos estáticos',
        'GET  /health - Health check',
        'GET  /debug/routes - Esta rota'
      ],
      'note': 'Todos os endpoints (exceto auth e motd) requerem Authorization: Bearer <token>'
    });
  }

  // Validação de email
  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.') && email.length > 5;
  }

  // Validação de senha
  bool _isValidPassword(String password) {
    if (password.length < 6) return false;
    
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    
    return hasLetter && hasNumber;
  }

  // Handler principal com middlewares
  Handler get handler => Pipeline()
      .addMiddleware(corsHeaders(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
          'Access-Control-Max-Age': '86400',
        }
      ))
      .addMiddleware(authMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router);
}

  // Função principal
void main() async {
  final api = SafeEduAPI();
  
  // Criar diretório uploads se não existir
  final uploadsDir = Directory('uploads');
  if (!await uploadsDir.exists()) {
    await uploadsDir.create(recursive: true);
  }
  
  // Configuração de porta e host para Fly.io
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  
  final server = await serve(
    api.handler,
    host,
    port,
  );
  
  // Logs de inicialização
  print('🚀 SafeEdu API executando em http://$host:$port');
  print('🌐 Ambiente: ${Platform.environment['FLY_APP_NAME'] ?? 'local'}');
  print('🔑 JWT Secret: ${jwtSecret.substring(0, 10)}...');
  print('⏰ Token Duration: ${tokenDuration.inHours}h');
  print('');
  print('📚 Endpoints disponíveis:');
  print('   POST /jwt/generate_token - Autenticação');
  print('   POST /jwt/validate_token - Validar token');
  print('   GET  /A2/motd - Mensagem do dia');
  print('   GET  /A2/school_list - Lista de escolas');
  print('   GET  /A2/comments - Comentários');
  print('   POST /A2/comments - Adicionar comentário');
  print('   GET  /A2/prints - Lista de prints');
  print('   POST /A2/prints - Upload de print');
  print('   GET  /health - Health check');
  print('');
  print('👤 Usuários de teste:');
  print('   fred@fred.com / fred123');
  print('   julia@safeedu.com / julia123');
  print('');
  print('✅ API pronta para receber conexões!');
}