import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String gender;
  final String origin;
  final String location;
  final String image;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.gender,
    required this.origin,
    required this.location,
    required this.image,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      species: json['species'],
      gender: json['gender'],
      origin: json['origin']['name'],
      location: json['location']['name'],
      image: json['image'],
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Character> characters = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    performSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Search Characters'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    performSearch();
                  },
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  performSearch();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: fetchCharacters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  List<Character> characters = snapshot.data as List<Character>;

                  if (characters.isEmpty) {
                    return Center(
                      child: Text('No characters found'),
                    );
                  }

                  return ListView.builder(
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(characters[index].image),
                        ),
                        title: Text(characters[index].name),
                        subtitle: Text('Status: ${characters[index].status}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(character: characters[index]),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Character>> fetchCharacters() async {
    try {
      final response = await http.get(
        Uri.parse('https://rickandmortyapi.com/api/character/?name=${searchController.text}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> characterList = data['results'];

        if (characterList.isNotEmpty) {
          return characterList
              .map<Character>((character) => Character.fromJson(character))
              .toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        // Handle 404 status code (Not Found)
        print('No characters found for the given search query');
        return [];
      } else {
        // Print the error response for debugging
        print('Error response: ${response.statusCode}\n${response.body}');
        throw Exception('Failed to perform search');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }

  void performSearch() {
    fetchCharacters().then((characters) {
      setState(() {
        this.characters = characters;
      });
    });
  }
}

class DetailPage extends StatelessWidget {
  final Character character;

  DetailPage({required this.character});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(character.image),
          SizedBox(height: 20),
          Text('Status: ${character.status}'),
          Text('Species: ${character.species}'),
          Text('Gender: ${character.gender}'),
          Text('Origin: ${character.origin}'),
          Text('Location: ${character.location}'),
        ],
      ),
    );
  }
}
