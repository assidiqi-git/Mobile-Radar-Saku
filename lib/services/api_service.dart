import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../models/transfer.dart';
import '../models/user.dart';
import '../models/wallet.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthException extends ApiException {
  const AuthException() : super(statusCode: 401, message: 'Unauthenticated');
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    required Map<String, dynamic> errors,
  }) : super(statusCode: 422, errors: errors);

  Map<String, List<String>> get fieldErrors {
    final result = <String, List<String>>{};
    errors?.forEach((key, value) {
      if (value is List) {
        result[key] = value.cast<String>();
      }
    });
    return result;
  }
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost/api';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      AppConstants.clientTypeHeader: AppConstants.clientTypeMobile,
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = response.body.isEmpty ? '{}' : response.body;
    final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;

    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return json;
      case 401:
        throw const AuthException();
      case 422:
        throw ValidationException(
          message: json['message'] as String? ?? 'Validation failed',
          errors: json['errors'] as Map<String, dynamic>? ?? {},
        );
      default:
        throw ApiException(
          statusCode: response.statusCode,
          message: json['message'] as String? ?? 'Unexpected error',
        );
    }
  }

  // ---- Auth ----

  /// POST /login — returns token + user for mobile clients.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      _uri('/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  /// POST /register — returns token + user for mobile clients.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      _uri('/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return _handleResponse(response);
  }

  /// POST /logout
  Future<void> logout() async {
    try {
      await http.post(_uri('/logout'), headers: _headers);
    } catch (_) {
      // Ignore errors on logout
    }
  }

  /// GET /user
  Future<UserModel> getUser() async {
    final response = await http.get(_uri('/user'), headers: _headers);
    final data = await _handleResponse(response);
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ---- Wallets ----

  /// GET /wallets
  Future<List<WalletModel>> getWallets() async {
    final response = await http.get(_uri('/wallets'), headers: _headers);
    final data = await _handleResponse(response);
    final list = data['data'];
    if (list is! List) return [];
    return list.map((e) => WalletModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /wallets
  Future<WalletModel> storeWallet({
    required String name,
    required String type,
    double? balance,
  }) async {
    final body = <String, dynamic>{'name': name, 'type': type};
    if (balance != null) body['balance'] = balance;
    final response = await http.post(
      _uri('/wallets'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return WalletModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// PUT /wallets/{id}
  Future<WalletModel> updateWallet(
    String id, {
    String? name,
    String? type,
    double? balance,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (balance != null) body['balance'] = balance;
    final response = await http.put(
      _uri('/wallets/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return WalletModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// DELETE /wallets/{id}
  Future<void> deleteWallet(String id) async {
    final response = await http.delete(_uri('/wallets/$id'), headers: _headers);
    await _handleResponse(response);
  }

  // ---- Transaction Types ----

  /// GET /transaction-types (all pages)
  Future<List<TransactionTypeModel>> getTransactionTypes() async {
    final response =
        await http.get(_uri('/transaction-types'), headers: _headers);
    final data = await _handleResponse(response);
    final list = data['data'];
    if (list is! List) return [];
    return list
        .map((e) => TransactionTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Transaction Categories ----

  /// GET /transaction-categories
  Future<List<TransactionCategoryModel>> getTransactionCategories() async {
    final response =
        await http.get(_uri('/transaction-categories'), headers: _headers);
    final data = await _handleResponse(response);
    final list = data['data'];
    if (list is! List) return [];
    return list
        .map((e) =>
            TransactionCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Sync ----

  /// POST /sync/transactions — push batch (max 500)
  Future<Map<String, dynamic>> pushTransactions(
      List<TransactionModel> transactions) async {
    final payload = {
      'transactions': transactions.map((t) => t.toSyncPayload()).toList(),
    };
    final response = await http.post(
      _uri('/sync/transactions'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _handleResponse(response);
  }

  /// GET /sync/transactions/pull?last_synced_at=
  Future<List<TransactionModel>> pullTransactions({String? lastSyncedAt}) async {
    final queryParams = lastSyncedAt != null
        ? {'last_synced_at': lastSyncedAt}
        : <String, String>{};
    final response = await http.get(
      _uri('/sync/transactions/pull', queryParams),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'];
    if (list is! List) return [];
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Transfers ----

  /// POST /transfers
  Future<TransferModel> storeTransfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    double? fee,
    required String transferDate,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'transfer_date': transferDate,
    };
    if (fee != null) body['fee'] = fee;
    if (note != null) body['note'] = note;

    final response = await http.post(
      _uri('/transfers'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return TransferModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
