import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import './auth_service.dart';
import 'api_client.dart';

class PortfolioSetupService {
  final AuthService _authService;
  late final ApiClient _api;

  PortfolioSetupService(this._authService) {
    _api = ApiClient(_authService);
  }

  Future<bool> hasUserPortfolio() async {
    if (_authService.token == null) return false;
    try {
      final data = await _api.getJson('/api/portfolio/me');
      return data != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> createInitialPortfolio(
    String name,
    String? description,
    File excelFile,
  ) async {
    final bytes = await excelFile.readAsBytes();
    await _api.multipart(
      '/api/portfolio',
      fields: {
        'portfolioName': name,
        if (description != null) 'description': description,
      },
      fileBytes: bytes,
      filename: excelFile.path.split('/').last,
    );
  }

  Future<void> updatePortfolio(
    String name,
    String? description,
    File excelFile,
  ) async {
    final bytes = await excelFile.readAsBytes();
    // Backend currently uses POST for create; you can add PUT route if needed
    await _api.multipart(
      '/api/portfolio',
      fields: {
        'portfolioName': name,
        if (description != null) 'description': description,
      },
      fileBytes: bytes,
      filename: excelFile.path.split('/').last,
    );
  }
}