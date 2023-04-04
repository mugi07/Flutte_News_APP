import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:getwidget/getwidget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;
  late SearchBar _searchBar;
  bool _isSearching = false;
  Future<List<dynamic>>? _newsData;

  Future<List<dynamic>> fetchNewsData({String query = 'tesla'}) async {
    try {
      final dio = Dio();
      final response = await dio.get(
          'https://newsapi.org/v2/everything?q=$query&from=2023-03-04&sortBy=publishedAt&apiKey=26256720ec2a44bba18e64417934cea9');

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        return jsonResponse['articles'];
      } else {
        throw Exception('Failed to load news');
      }
    } catch (error) {
      throw Exception('Failed to load news: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _newsData = fetchNewsData();
    _searchBar = SearchBar(
      hintText: 'Search news...',
      inBar: true,
      buildDefaultAppBar: buildAppBar,
      setState: setState,
      onSubmitted: (value) {
        setState(() {
          _newsData = fetchNewsData(query: value);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _searchBar.build(context),
      body: FutureBuilder<List<dynamic>>(
        future: _newsData,
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                final article = snapshot.data![index];
                var date = DateTime.parse(article['publishedAt']);
                return Card(
                  child: Column(
                    children: <Widget>[
                      Image(
                        image: CachedNetworkImageProvider(
                            '${article['urlToImage']}'),
                      ),
                      ListTile(
                        title: Text(
                          '${article['title']}',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${article['author']}',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              'Published on: ${DateFormat.yMMMMd('en_US').format(date)}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'Source: ${article['source']['name']}',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.start,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Color.fromARGB(255, 219, 187, 7),
                            ),
                            child: Text(
                              'READ MORE',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebView(
                                    initialUrl: '${article['url']}',
                                    javascriptMode: JavascriptMode.unrestricted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error}',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 219, 187, 7),
              ),
            );
          }
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Text(
        'News',
        style: GoogleFonts.montserrat(
          fontSize: 30,
          color: const Color(0xfffcfcfc),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        _searchBar.getSearchAction(context),
      ],
    );
  }
}
