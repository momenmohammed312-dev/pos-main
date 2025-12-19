import 'package:flutter/material.dart';
import 'dart:io';

class ErrorHandler {
  static void handleFirebaseError(dynamic error, {String? customMessage}) {
    String userMessage = _getFirebaseErrorMessage(error);
    String logMessage = _getLogMessage(error, customMessage);
    
    // Log for developer
    debugPrint('Firebase Error: $logMessage');
    
    // Show user-friendly message (this will be called from UI components)
    showErrorSnackBar(userMessage);
  }
  
  static void handleNetworkError(dynamic error, {String? customMessage}) {
    String userMessage = _getNetworkErrorMessage(error);
    String logMessage = _getLogMessage(error, customMessage);
    
    // Log for developer
    debugPrint('Network Error: $logMessage');
    
    // Show user-friendly message
    showErrorSnackBar(userMessage);
  }
  
  static void handleGeneralError(dynamic error, {String? customMessage}) {
    String userMessage = _getGeneralErrorMessage(error);
    String logMessage = _getLogMessage(error, customMessage);
    
    // Log for developer
    debugPrint('General Error: $logMessage');
    
    // Show user-friendly message
    showErrorSnackBar(userMessage);
  }
  
  static String _getFirebaseErrorMessage(dynamic error) {
    if (error.toString().contains('network-error')) {
      return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من اتصالك وتحديث الصفحة.';
    } else if (error.toString().contains('permission-denied')) {
      return 'ليس لديك صلاحية للقيام بهذه العملية. يرجى التواصل مع مدير النظام.';
    } else if (error.toString().contains('not-found')) {
      return 'البيانات المطلوبة غير موجودة. يرجى المحاولة مرة أخرى.';
    } else if (error.toString().contains('already-exists')) {
      return 'البيانات موجودة بالفعل. يرجى استخدام بيانات مختلفة.';
    } else if (error.toString().contains('resource-exhausted')) {
      return 'تم تجاوز الحد المسموح. يرجى المحاولة مرة أخرى لاحقاً.';
    } else if (error.toString().contains('failed-precondition')) {
      return 'لا يمكن إتمام العملية حالياً. يرجى المحاولة مرة أخرى.';
    } else if (error.toString().contains('aborted')) {
      return 'تم إلغاء العملية. يرجى المحاولة مرة أخرى.';
    } else if (error.toString().contains('out-of-range')) {
      return 'البيانات خارج النطاق المسموح. يرجى التحقق من البيانات.';
    } else if (error.toString().contains('unimplemented')) {
      return 'هذه الميزة غير متاحة حالياً.';
    } else if (error.toString().contains('internal')) {
      return 'حدث خطأ داخلي في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
    } else if (error.toString().contains('unavailable')) {
      return 'الخدمة غير متاحة حالياً. يرجى المحاولة مرة أخرى لاحقاً.';
    } else if (error.toString().contains('data-loss')) {
      return 'حدث فقدان للبيانات. يرجى التحقق من البيانات والمحاولة مرة أخرى.';
    } else if (error.toString().contains('unauthenticated')) {
      return 'يجب تسجيل الدخول للقيام بهذه العملية.';
    } else if (error.toString().contains('timeout')) {
      return 'انتهت مدة الانتظار. يرجى المحاولة مرة أخرى.';
    } else {
      return 'حدث خطأ في الاتصال بقاعدة البيانات. يرجى المحاولة مرة أخرى.';
    }
  }
  
  static String _getNetworkErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك بالشبكة.';
    } else if (error is HttpException) {
      return 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
    } else if (error.toString().contains('timeout')) {
      return 'انتهت مدة الانتظار. يرجى التحقق من سرعة الإنترنت والمحاولة مرة أخرى.';
    } else if (error.toString().contains('connection refused')) {
      return 'لا يمكن الاتصال بالخادم. يرجى المحاولة مرة أخرى لاحقاً.';
    } else if (error.toString().contains('host not found')) {
      return 'لا يمكن العثور على الخادم. يرجى التحقق من العنوان.';
    } else {
      return 'حدث خطأ في الاتصال. يرجى التحقق من اتصالك بالإنترنت.';
    }
  }
  
  static String _getGeneralErrorMessage(dynamic error) {
    if (error is FormatException) {
      return 'تنسيق البيانات غير صحيح. يرجى التحقق من البيانات المدخلة.';
    } else if (error is ArgumentError) {
      return 'بيانات غير صالحة. يرجى التحقق من البيانات المدخلة.';
    } else if (error is StateError) {
      return 'حالة غير صالحة. يرجى إعادة تحميل الصفحة والمحاولة مرة أخرى.';
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }
  
  static String _getLogMessage(dynamic error, String? customMessage) {
    String logMessage = '';
    if (customMessage != null) {
      logMessage += '$customMessage: ';
    }
    logMessage += error.toString();
    
    // Add stack trace if available
    if (error is Error && error.stackTrace != null) {
      logMessage += '\nStack Trace: ${error.stackTrace}';
    }
    
    return logMessage;
  }
  
  static void showErrorSnackBar(String message, {BuildContext? context}) {
    // This method should be called from UI context
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'إغلاق',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
  
  static void showWarningSnackBar(String message, {BuildContext? context}) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'إغلاق',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
  
  static void showSuccessSnackBar(String message, {BuildContext? context}) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
