import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'user_model.dart';

class HomePage extends StatefulWidget {
  final String email;
  HomePage({required this.email});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String _result = "";
  String? _youtubeUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  void _fetchUsername() {
    var box = Hive.box<UserModel>('users');
    var user = box.get(widget.email);
    if (user != null) {
      setState(() {
        _username = user.username;
      });
    }
  }

  String cleanUrl(String url) {
    return url.split("?")[0]; // ✅ Removes query parameters
  }

  Future<void> processVideo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _result = "Please enter a YouTube URL.");
      return;
    }

    String processedUrl = cleanUrl(url); // ✅ Clean the URL before sending it

    setState(() {
      _youtubeUrl = processedUrl;
      _result = "Processing video... in home page";
    });

    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/process"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"url": processedUrl}), // ✅ Use the cleaned URL
    );

    if (response.statusCode == 200) {
      setState(() => _result = "Processing complete! You can now fetch transcript or summary.");
    } else {
      setState(() => _result = "Error: Could not process video.");
    }
  }




  Future<void> fetchTranscript() async {
    if (_youtubeUrl == null) {
      setState(() => _result = "Please process a YouTube URL first.");
      return;
    }

    print("🔍 Fetching transcript for $_youtubeUrl");
    final response = await http.get(Uri.parse("http://127.0.0.1:8000/transcript?url=$_youtubeUrl"));

    print("📥 Response status: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      setState(() => _result = jsonDecode(response.body)["transcript"]);
    } else {
      setState(() => _result = "Transcript not ready yet. Try again later.");
    }
  }

  Future<void> fetchSummary() async {
    if (_youtubeUrl == null) {
      setState(() => _result = "Please process a YouTube URL first.");
      return;
    }

    print("🔍 Fetching summary for $_youtubeUrl");
    final response = await http.get(Uri.parse("http://127.0.0.1:8000/summary?url=$_youtubeUrl"));

    print("📥 Response status: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      setState(() => _result = jsonDecode(response.body)["summary"]);
    } else {
      setState(() => _result = "Summary not ready yet. Try again later.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("YouTube Transcript & Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${_username ?? "User"}!", // Display retrieved username
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
            ),
            SizedBox(height: 20),
            Text("Enter the YouTube URL:", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: processVideo,
                  child: Text("Process Video"),
                ),
                ElevatedButton(
                  onPressed: fetchTranscript,
                  child: Text("Transcript"),
                ),
                ElevatedButton(
                  onPressed: fetchSummary,
                  child: Text("Summary"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Result:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
