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

import 'dart:async';
import 'dart:convert';

import 'package:boxbox/api/brightcove.dart';
import 'package:boxbox/helpers/loading_indicator_util.dart';
import 'package:boxbox/helpers/news_feed_widget.dart';
import 'package:boxbox/helpers/request_error.dart';
import 'package:boxbox/Screens/article.dart';
import 'package:boxbox/Screens/standings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class F1NewsFetcher {
  final String endpoint = "https://api.formula1.com";
  final String apikey = "qPgPPRJyGCIPxFT3el4MF7thXHyJCzAP";

  List formatResponse(Map responseAsJson) {
    List finalJson = responseAsJson['items'];
    List newsList = [];
    finalJson.forEach((element) {
      element['title'] = element['title'].replaceAll("\n", "");
      if (element['metaDescription'] != null) {
        element['metaDescription'] =
            element['metaDescription'].replaceAll("\n", "");
      }
      newsList.add(
        News(
          element['id'],
          element['articleType'],
          element['slug'],
          element['title'],
          element['metaDescription'],
          DateTime.parse(element['updatedAt']),
          element['thumbnail']['image']['url'],
        ),
      );
    });
    return newsList;
  }

  FutureOr<List> getLatestNews({String? tagId}) async {
    Uri url;
    if (tagId != null) {
      url = Uri.parse('$endpoint/v1/editorial/articles?limit=200&tags=$tagId');
    } else {
      url = Uri.parse('$endpoint/v1/editorial/articles?limit=200');
    }
    var response = await http.get(url, headers: {
      "Accept": "application/json",
      "apikey": apikey,
      "locale": "en",
    });

    Map<String, dynamic> responseAsJson =
        json.decode(utf8.decode(response.bodyBytes));

    if (tagId == null) {
      Hive.box('requests').put('news', responseAsJson);
    }
    return formatResponse(responseAsJson);
  }

  Future<Article> getArticleData(String articleId) async {
    Uri url = Uri.parse('$endpoint/v1/editorial/articles/$articleId');
    var response = await http.get(url, headers: {
      "Accept": "application/json",
      "apikey": apikey,
      "locale": "en",
    });
    Map<String, dynamic> responseAsJson =
        json.decode(utf8.decode(response.bodyBytes));

    Article article = Article(
      responseAsJson['id'],
      responseAsJson['slug'],
      responseAsJson['title'],
      DateTime.parse(responseAsJson['createdAt']),
      responseAsJson['articleTags'],
      responseAsJson['hero'],
      responseAsJson['body'],
      responseAsJson['relatedArticles'],
    );
    return article;
  }
}

class News {
  final String newsId;
  final String newsType;
  final String slug;
  final String title;
  final String subtitle;
  final DateTime datePosted;
  final String imageUrl;

  News(
    this.newsId,
    this.newsType,
    this.slug,
    this.title,
    this.subtitle,
    this.datePosted,
    this.imageUrl,
  );
}

class Article {
  final String articleId;
  final String articleSlug;
  final String articleName;
  final DateTime publishedDate;
  final List articleTags;
  final Map articleHero;
  final List articleContent;
  final List relatedArticles;

  Article(
    this.articleId,
    this.articleSlug,
    this.articleName,
    this.publishedDate,
    this.articleTags,
    this.articleHero,
    this.articleContent,
    this.relatedArticles,
  );
}

class NewsItem extends StatelessWidget {
  final News item;
  final bool inRelated;

  NewsItem(
    this.item,
    this.inRelated,
  );

  final String endpoint = 'https://formula1.com';
  final String articleLink = '/en/latest/article.';

  Widget build(BuildContext context) {
    String imageUrl = item.imageUrl;
    bool useDarkMode =
        Hive.box('settings').get('darkMode', defaultValue: true) as bool;
    String newsLayout =
        Hive.box('settings').get('newsLayout', defaultValue: 'big') as String;
    double width = MediaQuery.of(context).size.width;
    if (item.imageUrl.startsWith('https://www.formula1.com/')) {
      imageUrl = '${item.imageUrl}.transform/6col/image.jpg';
    }
    return inRelated
        ? Container(
            width: width / 2.1,
            height: 210,
            child: Padding(
              padding: EdgeInsets.only(top: 5),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArticleScreen(item.newsId, item.title, false),
                    ),
                  );
                },
                child: Card(
                  elevation: 5.0,
                  color: useDarkMode ? Color(0xff1d1d28) : Colors.white,
                  child: Column(
                    children: [
                      Container(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          placeholder: (context, url) => Container(
                            height: 90,
                            child: LoadingIndicatorUtil(),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.error_outlined,
                            color: useDarkMode ? Colors.white : Colors.black,
                          ),
                          fadeOutDuration: Duration(seconds: 1),
                          fadeInDuration: Duration(seconds: 1),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: useDarkMode ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Padding(
            padding: EdgeInsets.only(top: 5),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ArticleScreen(item.newsId, item.title, false),
                  ),
                );
              },
              child: Card(
                elevation: 5.0,
                color: useDarkMode ? Color(0xff1d1d28) : Colors.white,
                child: Column(
                  children: [
                    newsLayout != 'condensed' && newsLayout != 'small'
                        ? Container(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              placeholder: (context, url) => Container(
                                height: MediaQuery.of(context).size.width /
                                        (16 / 9) -
                                    5,
                                child: LoadingIndicatorUtil(),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.error_outlined,
                                color: useDarkMode
                                    ? Color(0xff1d1d28)
                                    : Colors.white,
                              ),
                              fadeOutDuration: Duration(seconds: 1),
                              fadeInDuration: Duration(seconds: 1),
                            ),
                          )
                        : Container(
                            height: 0.0,
                            width: 0.0,
                          ),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 5),
                      child: Row(
                        children: [
                          Text(
                            item.newsType.toUpperCase(),
                            style: TextStyle(
                              color: useDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.schedule,
                                  color:
                                      useDarkMode ? Colors.white : Colors.black,
                                  size: 20.0,
                                ),
                              ),
                              Text(
                                timeago.format(
                                  item.datePosted,
                                  locale: Localizations.localeOf(context)
                                      .toString(),
                                ),
                                style: TextStyle(
                                  color:
                                      useDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: useDarkMode ? Colors.white : Colors.black,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                        textAlign: TextAlign.justify,
                      ),
                      subtitle: newsLayout != 'big' && newsLayout != 'condensed'
                          ? null
                          : item.subtitle != null
                              ? Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.justify,
                                )
                              : Container(height: 0.0, width: 0.0),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

class NewsList extends StatefulWidget {
  final List items;
  final ValueListenable itemsValueNotifier;

  NewsList({
    Key? key,
    required this.items,
    required this.itemsValueNotifier,
  });
  @override
  _NewsListState createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> {
  late int perPage;
  int present = 0;
  List items = [];

  @override
  void initState() {
    super.initState();
    perPage = widget.items.length < 15 ? widget.items.length : 15;
    items.addAll(widget.items.getRange(present, present + perPage));
    present = present + perPage;
  }

  @override
  Widget build(BuildContext context) {
    List originalItems = widget.items;
    return ValueListenableBuilder(
      valueListenable: widget.itemsValueNotifier,
      builder: (context, value, child) => ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        itemCount:
            (present <= originalItems.length) ? items.length + 1 : items.length,
        itemBuilder: (context, index) {
          return index == items.length
              ? Padding(
                  padding: EdgeInsets.only(
                    top: 5,
                    bottom: 10,
                  ),
                  child: ElevatedButton(
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 7, right: 7, top: 5, bottom: 5),
                      child: Text(
                        AppLocalizations.of(context)?.loadMore ?? 'Load more',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    onPressed: (() {
                      setState(
                        () {
                          if ((present + perPage) > originalItems.length) {
                            items.addAll(originalItems.getRange(
                                present, originalItems.length));
                          } else {
                            items.addAll(
                              originalItems.getRange(
                                  present, present + perPage),
                            );
                          }
                          present = present + perPage;
                        },
                      );
                    }),
                  ),
                )
              : NewsItem(
                  items[index],
                  false,
                );
        },
      ),
    );
  }
}

class ArticleRenderer extends StatelessWidget {
  final Article item;
  ArticleRenderer(this.item);

  Future<Article> getArticleData(String articleId) async {
    return await F1NewsFetcher().getArticleData(articleId);
  }

  Widget build(BuildContext context) {
    return FutureBuilder<Article>(
      future: getArticleData(item.articleId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Text(
            snapshot.error.toString(),
          );
        return snapshot.hasData
            ? JoinArticlesParts(
                snapshot.data!,
              )
            : LoadingIndicatorUtil();
      },
    );
  }
}

class JoinArticlesParts extends StatelessWidget {
  final Article article;

  JoinArticlesParts(this.article);

  Widget build(BuildContext context) {
    bool useDarkMode =
        Hive.box('settings').get('darkMode', defaultValue: true) as bool;
    List articleContent = article.articleContent;
    List<Widget> widgetsList = [];

    if (article.articleHero['contentType'] == 'atomVideo') {
      widgetsList.add(
        VideoRenderer(
          article.articleHero['fields']['videoId'],
        ),
      );
    } else {
      widgetsList.add(
        ImageRenderer(
          article.articleHero['fields']['image']['url'],
        ),
      );
    }
    List<Widget> tagsList = [];
    article.articleTags.forEach(
      (tag) => tagsList.add(
        Padding(
          padding: EdgeInsets.only(
            top: 10,
            left: 5,
            right: 5,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(
                        tag['fields']['tagName'],
                      ),
                    ),
                    backgroundColor: useDarkMode
                        ? Theme.of(context).backgroundColor
                        : Colors.white,
                    body: NewsFeedWidget(tagId: tag['id']),
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(7),
                child: Text(
                  tag['fields']['tagName'],
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    widgetsList.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.only(left: 5, right: 5),
          child: Row(
            children: tagsList,
          ),
        ),
      ),
    );

    articleContent.forEach(
      (element) {
        if (element['contentType'] == 'atomRichText') {
          widgetsList.add(
            TextParagraphRenderer(element['fields']['richTextBlock']),
          );
        } else if (element['contentType'] == 'atomVideo') {
          widgetsList.add(
            VideoRenderer(
              element['fields']['videoId'],
            ),
          );
        } else if (element['contentType'] == 'atomImage') {
          widgetsList.add(
            ImageRenderer(
              element['fields']['image']['url'],
              caption: element['fields']['caption'],
            ),
          );
        } else if (element['contentType'] == 'atomQuiz') {
          widgetsList.add(
            AspectRatio(
              aspectRatio: 748 / 598,
              child: WebView(
                javascriptMode: JavascriptMode.unrestricted,
                initialUrl:
                    'https://www.riddle.com/view/${element['fields']['riddleId']}',
                zoomEnabled: true,
                gestureRecognizers: [
                  Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer()),
                  Factory<HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer()),
                  Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer()),
                ].toSet(),
              ),
            ),
          );
        } else if (element['contentType'] == 'atomImageGallery') {
          List<Widget> galleryWidgets = [];
          element['fields']['imageGallery'].forEach(
            (element) => galleryWidgets.add(
              Container(
                width: MediaQuery.of(context).size.width,
                child: ImageRenderer(
                  element['url'],
                ),
              ),
            ),
          );
          widgetsList.add(
            CarouselSlider(
              items: galleryWidgets,
              options: CarouselOptions(
                viewportFraction: 1,
                aspectRatio: 16 / 9,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 7),
              ),
            ),
          );
        } else if (element['contentType'] == 'atomSocialPost' &&
            element['fields']['postType'] == 'Twitter') {
          widgetsList.add(
            Container(
              height: 400,
              child: WebView(
                javascriptMode: JavascriptMode.unrestricted,
                gestureRecognizers: [
                  Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer()),
                  Factory<HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer()),
                  Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer()),
                ].toSet(),
                initialUrl: element['fields']['postUrl'],
              ),
            ),
          );
        } else {
          widgetsList.add(
            Container(
              height: 100,
              child: Center(
                child: Text(
                  'Unsupported widget ¯\\_(ツ)_/¯\nType: ${element['contentType']}',
                  style: TextStyle(
                    color: useDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );

    widgetsList.add(
      Padding(
        padding: EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: useDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () => Share.share(
                          "https://www.formula1.com/en/latest/article.${article.articleSlug}.${article.articleId}.html",
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.share ?? 'Share',
                        style: TextStyle(
                          color: useDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.schedule,
                          color: useDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {},
                      ),
                      Text(
                        DateFormat('kk:mm\nyyyy-MM-dd')
                            .format(article.publishedDate),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: useDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    List<NewsItem> relatedArticles = [];
    article.relatedArticles.forEach(
      (article) => relatedArticles.add(
        NewsItem(
          News(
            article['id'],
            article['articleType'],
            article['slug'],
            article['title'],
            article['metaDescription'],
            DateTime.parse(article['updatedAt']),
            article['thumbnail']['image']['url'],
          ),
          true,
        ),
      ),
    );
    widgetsList.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: relatedArticles,
        ),
      ),
    );
    return SingleChildScrollView(
      child: Column(
        children: widgetsList,
      ),
    );
  }
}

class TextParagraphRenderer extends StatelessWidget {
  final String text;
  TextParagraphRenderer(this.text);

  Widget build(BuildContext context) {
    bool useDarkMode =
        Hive.box('settings').get('darkMode', defaultValue: true) as bool;
    bool useDefaultFontForArticles = Hive.box('settings')
        .get('useDefaultFontForArticles', defaultValue: false) as bool;
    return Padding(
      padding: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
      ),
      child: MarkdownBody(
        data: text,
        selectable: true,
        onTapLink: (text, url, title) {
          if (url!.startsWith('https://www.formula1.com/en/latest/article.')) {
            String articleId = url.substring(43, url.length - 5).split('.')[1];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleScreen(
                  articleId,
                  text,
                  true,
                ),
              ),
            );
          } else if (url.startsWith('https://www.formula1.com/en/results')) {
            String standingsType =
                url.substring(0, url.length - 5).split('/')[5];
            if (standingsType == "driver-standings") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      centerTitle: true,
                      title: Text(
                        AppLocalizations.of(context)!.standings,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    body: StandingsScreen(),
                  ),
                ),
              );
            } else if (standingsType == "constructor-standings") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      centerTitle: true,
                      title: Text(
                        AppLocalizations.of(context)!.standings,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    body: StandingsScreen(
                      switchToTeamStandings: true,
                    ),
                  ),
                ),
              );
            } else if (url.startsWith(
                "https://www.formula1.com/en/racing/${RegExp(r'\d{4}')}/")) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      centerTitle: true,
                      title: Text(
                        'Dead end',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    body: Text('This should not be possible... but it is...'),
                  ),
                ),
              );
            } else {
              launchUrl(Uri.parse(url));
            }
          } else {
            launchUrl(Uri.parse(url));
          }
        },
        styleSheet: MarkdownStyleSheet(
          strong: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          p: TextStyle(
            fontSize: 14,
            color: useDarkMode ? Colors.white : Colors.black,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
          pPadding: EdgeInsets.only(
            top: 10,
            bottom: 10,
          ),
          a: TextStyle(
            color: Theme.of(context).primaryColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.normal,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
          h1: TextStyle(
            color: useDarkMode ? Colors.white : Colors.black,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
          h2: TextStyle(
            color: useDarkMode ? Colors.white : Colors.black,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
          h3: TextStyle(
            color: useDarkMode ? Colors.white : Colors.black,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
          h4: TextStyle(
            color: useDarkMode ? Colors.white : Colors.black,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
          listBullet: TextStyle(
            color: useDarkMode ? Colors.white : Colors.black,
            fontFamily: useDefaultFontForArticles ? 'Roboto' : 'Formula1',
          ),
        ),
      ),
    );
  }
}

class ImageRenderer extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final bool? inSchedule;
  ImageRenderer(
    this.imageUrl, {
    this.caption,
    this.inSchedule,
  });

  Widget build(BuildContext context) {
    bool useDarkMode =
        Hive.box('settings').get('darkMode', defaultValue: true) as bool;
    return Padding(
      padding: EdgeInsets.only(
        bottom: inSchedule != null ? 0 : 10,
      ),
      child: inSchedule != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Container(
                height: MediaQuery.of(context).size.width / (16 / 9),
                child: LoadingIndicatorUtil(),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error_outlined),
              fadeOutDuration: Duration(seconds: 1),
              fadeInDuration: Duration(seconds: 1),
            )
          : GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.only(
                        top: 52,
                        bottom: 50,
                      ),
                      insetPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.transparent,
                      content: Builder(
                        builder: (context) {
                          return Container(
                            width: double.infinity - 10,
                            child: InteractiveViewer(
                              minScale: 0.1,
                              maxScale: 6,
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  Card(
                                    elevation: 5.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      placeholder: (context, url) => Container(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                (16 / 9),
                                        child: LoadingIndicatorUtil(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                        Icons.error_outlined,
                                      ),
                                      fadeOutDuration: Duration(seconds: 1),
                                      fadeInDuration: Duration(seconds: 1),
                                      fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: useDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) => Container(
                      height: MediaQuery.of(context).size.width / (16 / 9),
                      child: LoadingIndicatorUtil(),
                    ),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error_outlined),
                    fadeOutDuration: Duration(seconds: 1),
                    fadeInDuration: Duration(seconds: 1),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: caption != null
                        ? Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(4),
                            color: Colors.black.withOpacity(0.7),
                            child: Text(
                              caption ?? '',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Container(),
                  ),
                ],
              ),

              //child: Container(
              //  height: MediaQuery.of(context).size.height * 0.3,
              //  decoration: BoxDecoration(
              //    image: DecorationImage(
              //      fit: BoxFit.contain,
              //      image: CachedNetworkImageProvider(
              //        imageUrl,
              //      ),
              //    ),
              //  ),
              //  alignment: Alignment.bottomCenter,
              //  child: caption != null
              //      ? Container(
              //          width: double.infinity,
              //          padding: EdgeInsets.all(4),
              //          color: Colors.black.withOpacity(0.7),
              //          child: Text(
              //            caption,
              //            style: TextStyle(
              //              color: Colors.white,
              //            ),
              //           textAlign: TextAlign.center,
              //          ),
              //        )
              //      : Container(),
              //),
            ),
    );
  }
}

class VideoRenderer extends StatefulWidget {
  final String videoId;

  VideoRenderer(
    this.videoId,
  );
  @override
  _VideoRendererState createState() => _VideoRendererState();
}

class _VideoRendererState extends State<VideoRenderer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext build) {
    return FutureBuilder<String>(
      future: BrightCove().getVideoLink(widget.videoId),
      builder: (context, snapshot) => snapshot.hasError
          ? RequestErrorWidget(
              snapshot.error.toString(),
            )
          : snapshot.hasData
              ? VideoPlayer(snapshot.data!)
              : Container(
                  height: MediaQuery.of(context).size.width / (16 / 9),
                  child: LoadingIndicatorUtil(),
                ),
    );
  }
}

class VideoPlayer extends StatefulWidget {
  final String videoUrl;

  VideoPlayer(
    this.videoUrl,
  );
  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late ChewieController chewieController;
  late VideoPlayerController videoPlayerController;
  late bool isLoaded;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = videoPlayerController.initialize().then((_) {
      setState(() {});
    });
    bool useDarkMode =
        Hive.box('settings').get('darkMode', defaultValue: true) as bool;
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoInitialize: true,
      aspectRatio: 16 / 9,
      allowedScreenSleep: false,
      autoPlay: false,
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(
              color: useDarkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext build) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        return snapshot.connectionState == ConnectionState.done
            ? SafeArea(
                child: AspectRatio(
                  aspectRatio: videoPlayerController.value.aspectRatio,
                  child: Chewie(
                    key: new PageStorageKey(widget.videoUrl),
                    controller: chewieController,
                  ),
                ),
              )
            : Container(
                height: MediaQuery.of(context).size.width / (16 / 9),
                child: LoadingIndicatorUtil(),
              );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
    chewieController.dispose();
  }
}
