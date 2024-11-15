import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MovieApp());
}

class MovieApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Search & Favorites',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MovieSearchScreen(),
    );
  }
}

class MovieSearchScreen extends StatefulWidget {
  @override
  _MovieSearchScreenState createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List _movies = [];
  List<String> _favorites = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _toggleFavorite(String movie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(movie)) {
        _favorites.remove(movie);
      } else {
        _favorites.add(movie);
      }
    });
    await prefs.setStringList('favorites', _favorites);
  }

  Future<void> _searchMovies(String query) async {
    setState(() {
      _isLoading = true;
    });
    final apiKey = '72fc6acb9361f062a12ce4d12b9e5cf3';
    final url = Uri.parse('http://api.themoviedb.org/3/search/movie/?s=$query&apikey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _movies = data['Search'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _movies = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Search & Favorites'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(favorites: _favorites),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search for a movie',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchMovies(_controller.text);
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        final movie = _movies[index];
                        final isFavorite = _favorites.contains(movie['imdbID']);
                        return ListTile(
                          leading: Image.network(
                            movie['Poster'],
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.movie),
                          ),
                          title: Text(movie['Title']),
                          subtitle: Text(movie['Year']),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () => _toggleFavorite(movie['imdbID']),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<String> favorites;

  const FavoritesScreen({Key? key, required this.favorites}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
      ),
      body: favorites.isEmpty
          ? Center(child: Text('No favorites added yet!'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(favorites[index]),
                );
              },
            ),
    );
  }
}

