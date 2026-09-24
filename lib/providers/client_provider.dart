import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/client.dart';

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  bool _isLoading = false;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  ClientProvider() {
    loadClients();
  }

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();
    try {
      _clients = await AppDatabase.instance.getClients();
    } catch (e) {
      debugPrint('Error loading clients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Client?> getClientById(int id) async {
    return await AppDatabase.instance.getClientById(id);
  }

  Future<int> addClient(Client client) async {
    final id = await AppDatabase.instance.createClient(client);
    await loadClients();
    return id;
  }

  Future<void> updateClient(Client client) async {
    await AppDatabase.instance.updateClient(client);
    await loadClients();
  }

  Future<void> deleteClient(int clientId) async {
    await AppDatabase.instance.deleteClient(clientId);
    await loadClients();
  }
}
