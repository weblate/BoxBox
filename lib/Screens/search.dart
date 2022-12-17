/*
 *  This file is part of BoxBox (https://github.com/BrightDV/BoxBox).
 * 
 * BoxBox is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BoxBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BoxBox.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2022, BrightDV
 */

import 'package:boxbox/Screens/article.dart';
import 'package:boxbox/api/searx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  String query = '';
  List results = [];

  _searchArticles() async {
    List articlesList = await SearXSearch().searchArticles(query);
    setState(
      () {
        results = articlesList;
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool useDarkMode =
        Hive.box('settings').get('darkMode', defaultValue: true) as bool;
    return Scaffold(
      backgroundColor:
          useDarkMode ? Theme.of(context).backgroundColor : Colors.white,
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          height: 40,
          child: Center(
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: Colors.white,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                hintText: 'Search',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey.shade200,
                ),
              ),
              onChanged: (text) {
                setState(
                  () {
                    query = text;
                  },
                );
              },
              onSubmitted: (value) => setState(
                () {
                  _searchArticles();
                },
              ),
            ),
          ),
        ),
      ),
      body: results.length != 0
          ? ListView.builder(
              itemCount: results.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.all(5),
                  child: ListTile(
                      tileColor: useDarkMode
                          ? Color(0xff1d1d28)
                          : Colors.grey.shade400,
                      title: Text(
                        results[index]['title'],
                        style: TextStyle(
                          color: useDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        results[index]['content'],
                        style: TextStyle(
                          color: useDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        maxLines: 3,
                        textAlign: TextAlign.justify,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleScreen(
                              results[index]['url'].split('.')[4],
                              ' ',
                              true,
                            ),
                          ),
                        );
                      }),
                );
              },
            )
          : Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  AppLocalizations.of(context)!.noResults,
                  style: TextStyle(
                    color: useDarkMode ? Colors.white : Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
    );
  }
}