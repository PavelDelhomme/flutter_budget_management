import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionDetailsModal extends StatelessWidget {
  final DocumentSnapshot transaction;

  const TransactionDetailsModal({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final description = transaction['description'] ?? '';
    final amount = transaction['amount'] ?? 0.0;
    final date = (transaction['date'] as Timestamp).toDate();
    final isRecurring = transaction['isRecurring'] ?? false;
    final receiptUrl = transaction['receiptUrl'];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Wrap(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "Détails de la transaction",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          ),
          const SizedBox(height: 10),
          Text('Description : $description', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text('Montant : \$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text('Date : ${DateFormat.yMMMd().format(date)}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text('Transaction récurrente : ${isRecurring ? 'Oui' : 'Non'}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          if (receiptUrl != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reçu :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageScreen(imageUrl: receiptUrl),
                      ),
                    );
                  },
                  child: Image.network(
                    receiptUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}


class ImageScreen extends StatelessWidget {
  final String imageUrl;

  const ImageScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçu"),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
