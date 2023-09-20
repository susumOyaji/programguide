import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:developer';
//import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // "DEBUG"を非表示にする
      //title: 'Stock Data',
      theme: ThemeData(
        canvasColor: const Color.fromARGB(255, 10, 10, 10), // ベースカラーを変更する
      ),
      home: const _MyHomePage(),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  const _MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
//List<String> buttonNames =
  //    List.generate(10, (index) => 'Button ${index + 1}');

  //bool isNameChanged = false;
  final TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _textEditingController2 = TextEditingController();
  final TextEditingController _textEditingController3 = TextEditingController();

  List<Map<String, dynamic>> stockdataList = [];
  Future<List<Map<String, dynamic>>>? scrapedData;
  //String currentPageUrl = "";
  //String nextindex = "0";
  String grandWaves = "3";
  String bsDigital = "1";
  String skyPerfect = "2";
  int waveint = 0;

  //String page = "1";
  //int baseindex = 0;
  //int totalpages = 0;
  int currentPage = 0;

  //String keyWord = "";
  String idol = "";

  String systemState = "Redy...";
  String outputState = "Redy...";
  String fraction = "";

  //List<bool> selectedValues = [false, false, false];
  List<bool> buttonStates = List.generate(10, (_) => false);

  //Future<List<Map<String, dynamic>>>? returnMap;

  //List<bool> buttonStates =
  //    List.generate(10, (index) => index == 0 ? true : false);

  static List<Map<String, dynamic>> unsetdata = [
    {"Id": 0, "ButtonName": "", "SearchWard": ""},
    {"Id": 1, "ButtonName": "", "SearchWard": ""},
    {"Id": 2, "ButtonName": "", "SearchWard": ""},
    {"Id": 3, "ButtonName": "", "SearchWard": ""},
    {"Id": 4, "ButtonName": "", "SearchWard": ""},
    {"Id": 5, "ButtonName": "", "SearchWard": ""},
    {"Id": 6, "ButtonName": "", "SearchWard": ""},
    {"Id": 7, "ButtonName": "", "SearchWard": ""},
    {"Id": 8, "ButtonName": "", "SearchWard": ""},
    {"Id": 9, "ButtonName": "", "SearchWard": ""}
  ];

  @override
  void initState() {
    super.initState();

    loadData();

    idol = ""; //data[index]["SearchWard"];
    currentPage = 0;
    //scrapePage(currentPage);
    scrapePageGguid(currentPage);
    //deleteData();
  }

  // データの取得
  Future<void> loadData() async {
    //setState(() {
    stockdataList = []; //Load Data to init
    //});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('stockdataList');
    if (encodedData != null) {
      setState(() {
        List<dynamic> decodedData = json.decode(encodedData);
        stockdataList = decodedData.cast<Map<String, dynamic>>();
        systemState = 'loadDate successfully.';
      });
    } else {
      setState(() {
        stockdataList = unsetdata;
        saveData();
      });
    }
  }

  Future<void> removeData(int index) async {
    List<dynamic> data = stockdataList; //await loadData();
    if (index >= 0 && index < data.length) {
      data.removeAt(index);
      saveData();
    }
  }

  Future<void> deleteData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Remove data for the 'data' key.
    await prefs.remove('stockdataList');
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(stockdataList);
    await prefs.setString('stockdataList', encodedData);
    setState(() {
      systemState = "On saveData";
    });
  }

  Future<void> addData(Map<String, dynamic> stocknewData) async {
    // IDの重複チェック
    bool isDuplicateId = false;
    int newId = stocknewData["Id"];
    for (Map<String, dynamic> existingData in stockdataList) {
      int existingId = existingData["Id"];
      if (existingId == newId) {
        isDuplicateId = true;
        break;
      }
    }

    if (!isDuplicateId) {
      // 新しいデータを追加
      stockdataList.add(stocknewData);

      // IDで昇順ソート
      stockdataList.sort((a, b) => (a["Id"]).compareTo(b["Id"]));

      await saveData();
      setState(() {
        systemState = 'Data added and sorted successfully.';
      });
    } else {
      setState(() {
        systemState =
            'Data with the same ID already exists. Duplicate registration prevented.';
      });
    }
  }

  void updateStockData(Map<String, dynamic> newData) async {
    for (int i = 0; i < stockdataList.length; i++) {
      if (stockdataList[i]['Id'] == newData['Id']) {
        stockdataList[i] = newData;
        saveData();
        break;
      }
    }
  }

  void goToNextPage() {
    currentPage = currentPage + 20;
    //scrapePage(currentPage);
    scrapePageGguid(currentPage);
  }

  void goToPreviousPage() {
    if (currentPage > 1) {
      currentPage = currentPage - 20;
      //scrapePage(currentPage);
      scrapePageGguid(currentPage);
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////
  Future<void> scrapePage(int thispage) async {
    int totalpages = 0;
    //page = startpage.toString();
    log(idol);
    //int waveint = grandWaves + bsDigital;
    String wave = (grandWaves + bsDigital).toString();

    String originalString = idol;
    String encodedString = Uri.encodeComponent(
        originalString); //URL内に特殊文字や予約語（＆等）が含まれる場合にエンコードする、その文字を安全に表現するための方法

    final uri = Uri.parse(
        'https://www.tvkingdom.jp/schedulesBySearch.action?stationPlatformId=$wave&condition.keyword=$encodedString&submit=%E6%A4%9C%E7%B4%A2&index=${(thispage).toString()}'); // URLをURIオブジェクトに変換
//https://www.tvkingdom.jp/schedulesBySearch.action?stationPlatformId=0&condition.keyword=H&submit=%E6%A4%9C%E7%B4%A2&index=0
//https://www.tvkingdom.jp/schedulesBySearch.action?stationPlatformId=0&condition.keyword=H&submit=%E6%A4%9C%E7%B4%A2&index=0
//https://www.tvkingdom.jp/schedulesBySearch.action?stationPlatformId=0&condition.keyword=H&submit=%E6%A4%9C%E7%B4%A2&index=20
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);

      log("startpage: $thispage");

      //検出件数取得
      final next = document.getElementsByClassName('listIndexNum mgT5');
      final nextElement = next[0].text;
      final itemCountMatch =
          RegExp(r'(\d+(?:,\d+)?)件中').firstMatch(nextElement);
      var detections = itemCountMatch?.group(1);

      // 正規表現を使用して数字を抜き出す
      RegExp regExp = RegExp(r'\d+');
      Iterable<RegExpMatch> matches = regExp.allMatches(nextElement);
      // マッチした数字を文字列から整数に変換して返す
      int extractedNumber = int.parse(matches.last.group(0)!);
      log("NextPage: $extractedNumber");
      setState(() {
        currentPage = thispage;
        log("currentPage: $currentPage");
      });

      if (detections != null) {
        int pages = int.parse(detections.replaceAll(',', ''));
        totalpages = (pages / 20).ceil();
        //page = totalpages.toString();
      }

      log("DetectionPages: $totalpages");
      outputState = "DetectionPages: $totalpages";

      // スクレイピング対象の要素を抽出して処理
      //List<Map<String, dynamic>> newData = extractData(document); // 必要に応じて関数を実装
      setState(() {
        scrapedData = extractData(document); //newData;
        fraction = "${(extractedNumber / 20).ceil()}/$totalpages";
      });
    } else {
      log('Failed to load page');
    }
  }

  Future<List<Map<String, dynamic>>> extractData(document) async {
    List<Map<String, dynamic>> dataList = [];
    String trimmedText;
    List<String> codeArray = [];
    int index = 0; // カウンタ変数

    // スクレイピング対象の要素を抽出してリストに追加する処理
    // h2要素内のテキストを取得
    final tvspanElements = document.querySelectorAll('h2 a').toList();

    if (tvspanElements.isNotEmpty) {
      final limitedElements = tvspanElements.sublist(
          0,
          tvspanElements
              .length); // 最初のcount要素のみを取得,元のリストから一部の要素を抽出して新しいサブリストを作成するためのものです

      for (final element in limitedElements) {
        // 放送日と時間を取得
        final pElements = document.querySelectorAll('p.utileListProperty');
        final dateAndTime =
            pElements.isNotEmpty ? pElements[index].text.trim() : '';
        if (dateAndTime != null) {
          trimmedText = dateAndTime.replaceAll('\n', '');
          codeArray = trimmedText.split(' ');

          Map<String, dynamic> mapString = {
            "Title": element.text,
            "Date": codeArray[0],
            "Day": codeArray[1],
            "StartTime": codeArray[2],
            "From": codeArray[3], // spanTexts[29],
            "EndTime": codeArray[4],
            "Airtime": codeArray[16],
            "Channels": codeArray[26],
            "Channels2": codeArray[27]
          };
          dataList.add(mapString);
          index++;
        }
      }
    } else {
      Map<String, dynamic> mapString = {
        "Title": "Nothing at the moment....",
        "Date": "",
        "Day": "",
        "StartTime": "",
        "From": "",
        "EndTime": "",
        "Airtime": "",
        "Channels": "",
        "Channels2": ""
      };
      dataList.add(mapString);
    }

    return dataList;
  }

  Future<void> scrapePageGguid(int thispage) async {
    int totalpages = 0;
    int count = 0;
    //int waveint = grandWaves + bsDigital + SKYPerfect;

    String wave = waveint.toString();
    List<Map<String, dynamic>> dataList = [];

    String originalString = idol;
    String encodedString = Uri.encodeComponent(
        originalString); //URL内に特殊文字や予約語（＆等）が含まれる場合にエンコードする、その文字を安全に表現するための方法
    log("grand: $grandWaves");
    log("bs: $bsDigital");
    log("Sky: $skyPerfect");
    log(originalString);

    // テレビ番組のスケジュールを取得するURLを設定します。

    final uri = Uri.parse(
        'https://bangumi.org/search?si_type%5B%5D=$grandWaves&si_type%5B%5D=$bsDigital&si_type%5B%5D=$skyPerfect&genre_id=%E5%85%A8%E3%81%A6&q=$originalString&area_code=23');
    //https://bangumi.org/search?si_type%5B%5D=3&genre_id=%E5%85%A8%E3%81%A6&q=HiHI+jets&area_code=23

    //https://bangumi.org/search?si_type%5B%5D=3&genre_id=%E5%85%A8%E3%81%A6&q=$encodedString&area_code=23 地上波 一覧
    //https://bangumi.org/search?si_type%5B%5D=1&genre_id=%E5%85%A8%E3%81%A6&q=King%26Prince&area_code=23 BS 一覧
    //https://bangumi.org/search?si_type%5B%5D=2&genre_id=%E5%85%A8%E3%81%A6&q=King%26Prince&area_code=23 sky　一覧
    //https://bangumi.org/search?si_type%5B%5D=3&si_type%5B%5D=1&si_type%5B%5D=2&genre_id=%E5%85%A8%E3%81%A6&q=$encodedStringe&area_code=23 全部 一覧
    //https://bangumi.org/search?si_type%5B%5D=3&si_type%5B%5D=1&genre_id=%E5%85%A8%E3%81%A6&q=HiHI%2B+jets&area_code=23  地上波+BS
    //https://bangumi.org/search?si_type%5B%5D=1&si_type%5B%5D=2&genre_id=%E5%85%A8%E3%81%A6&q=HiHI%2B+jets&area_code=23  BS+SKY
    //https://bangumi.org/search?si_type%5B%5D=3&si_type%5B%5D=2&genre_id=%E5%85%A8%E3%81%A6&q=HiHI%2B+jets&area_code=23  地上波+SKY

    //https://bangumi.org/search?genre_id=%E5%85%A8%E3%81%A6&q=King+Prince&area_code=23

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);

      // スクレイピング対象の要素を抽出して処理
      //List<Map<String, dynamic>> newData = extractData(document); // 必要に応じて関数を実装
      setState(() {
        scrapedData = extractDataGguid(document); //newData;
        //fraction = "${(extractedNumber / 20).ceil()}/$totalpages";
      });
    } else {
      log('Failed to load page');
    }
  }

  Future<List<Map<String, dynamic>>> extractDataGguid(document) async {
    List<Map<String, dynamic>> dataList = [];
    String trimmedText;
    List<String> codeArray = [];
    int index = 0; // カウンタ変数

    // スクレイピング対象の要素を抽出してリストに追加する処理
    // h2要素内のテキストを取得
    final tvspanElements = document.querySelectorAll('.program_title').toList();

    if (tvspanElements.isNotEmpty) {
      final limitedElements = tvspanElements.sublist(
          0,
          tvspanElements
              .length); // 最初のcount要素のみを取得,元のリストから一部の要素を抽出して新しいサブリストを作成するためのものです

      for (final element in limitedElements) {
        // 放送日と時間を取得
        final pElements = document.querySelectorAll('.program_supplement');
        final dateAndTime =
            pElements.isNotEmpty ? pElements[index].text.trim() : '';
        if (dateAndTime != null) {
          trimmedText = dateAndTime.replaceAll('　', ' ');
          codeArray = trimmedText.split(' ');

          Map<String, dynamic> mapString = {
            "Title": element.text,
            "Date": codeArray[0],
            "Day": codeArray[1],
            "StartTime": codeArray[2],
            "Channels": codeArray[3],
          };
          dataList.add(mapString);
          index++;
        }
      }
    } else {
      Map<String, dynamic> mapString = {
        "Title": "Nothing at the moment....",
        "Date": "",
        "Day": "",
        "StartTime": "",
        "Channels": "",
      };
      dataList.add(mapString);
    }

    return dataList;
  }

  void editDialog(index) async {
    Map<String, dynamic> stocknewData = {};

    // ここにボタンが押されたときの処理を追加する
    showDialog(
      context: context,
      builder: (BuildContext context) {
        _textEditingController.text = stockdataList[index]['Id'].toString();
        _textEditingController2.text =
            stockdataList[index]['ButtonName'].toString();
        _textEditingController3.text =
            stockdataList[index]['SearchWard'].toString();

        return AlertDialog(
          title: Text('Button ${_textEditingController.text} was Longpressed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textEditingController2,
                decoration: const InputDecoration(hintText: 'ButtonName'),
              ),
              TextField(
                controller: _textEditingController3,
                decoration: const InputDecoration(hintText: 'SearchWard1'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                //String enteredText = _textEditingController.text;
                String enteredText2 = _textEditingController2.text;
                String enteredText3 = _textEditingController3.text;

                setState(() {
                  stocknewData = {
                    'Id': index,
                    'ButtonName': enteredText2,
                    'SearchWard': enteredText3
                  };
                });
                updateStockData(stocknewData);
                //addData(stocknewData);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int selectedValue = 1;

  Widget buttonView1(List<Map<String, dynamic>> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Theme(
          data: ThemeData(
            // 非選択時の色を指定
            unselectedWidgetColor: Colors.yellow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 25.0,
                    width: 40.0,
                    child: Radio(
                      activeColor: Colors.orange,
                      value: 1,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                          grandWaves = "3";
                          bsDigital = "1";
                          skyPerfect = "2";
                          //scrapePage(currentPage);
                          scrapePageGguid(currentPage);
                        });
                      },
                    ),
                  ),
                  const Text('Ground & BS & SKY Perfect',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 25.0,
                    width: 40.0,
                    child: Radio(
                      activeColor: Colors.orange,
                      value: 2,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                          grandWaves = "3";
                          bsDigital = "9";
                          skyPerfect = "9";
                          //scrapePage(currentPage);
                          scrapePageGguid(currentPage);
                        });
                      },
                    ),
                  ),
                  const Text('Ground Waves',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 25.0,
                    width: 40.0,
                    child: Radio(
                      activeColor: Colors.orange,
                      value: 3,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                          grandWaves = "9";
                          bsDigital = "1";
                          skyPerfect = "9";
                          //scrapePage(currentPage);
                          scrapePageGguid(currentPage);
                        });
                      },
                    ),
                  ),
                  const Text('BS Digital',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 25.0,
                    width: 40.0,
                    child: Radio(
                      activeColor: Colors.orange,
                      value: 4,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value!;
                          grandWaves = "9";
                          bsDigital = "9";
                          skyPerfect = "2";
                          //scrapePage(currentPage);
                          scrapePageGguid(currentPage);
                        });
                      },
                    ),
                  ),
                  const Text('SKY Perfect',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 5.0,
        ),
        Column(
          children: List.generate(2, (rowIndex) {
            return Row(
              children: List.generate(4, (columnIndex) {
                final index = rowIndex * 4 + columnIndex;
                return Column(children: [
                  const SizedBox(width: 105), // ボタンの間の間隔を設定
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonStates[index]
                          ? Colors.amber[900]
                          : Colors.grey, // ボタンの色を変更Colors.grey, //ボタンの背景色
                    ).merge(
                      ButtonStyle(
                        minimumSize: MaterialStateProperty.all(
                            const Size(100, 30)), // ボタンの最小サイズを指定
                        // 他のButtonStyle属性も追加できます
                      ),
                    ),
                    onLongPress: () {
                      editDialog(index);
                    },
                    onPressed: () {
                      setState(() {
                        for (int i = 0; i < buttonStates.length; i++) {
                          if (i == index) {
                            // 押されたボタンの色を変更
                            buttonStates[i] = true;
                          } else {
                            // 既に押されているボタンの色を元の色に戻す
                            buttonStates[i] = false;
                          }
                        }
                        idol = data[index]["SearchWard"];
                        currentPage = 0;
                        //scrapePage(currentPage);
                        scrapePageGguid(currentPage);
                        //returnMap = _fetchStockTv(data[index]["SearchWard"]);
                      });
                    },
                    child: Text(
                      data[index]["ButtonName"],
                      style: data[index]["SearchWard"] == ""
                          ? const TextStyle(color: Colors.black)
                          : const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8), // 2行の間隔を設定
                ]);
              }),
            );
          }),
        ),
      ],
    );
  }

  /*
  Widget buttonView(List<Map<String, dynamic>> data) {
    return Row(children: [
      const SizedBox(
        width: 30.0,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5.0),
          SizedBox(
            height: 30, // Rowの高さを調整する
            child: Row(
              children: [
                const Text('Terrestrial',
                    style: TextStyle(color: Colors.white)),
                //const SizedBox(width: 10),
                Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    onChanged: (bool val) {
                      // スイッチの状態を変更する処理
                      setState(() {
                        _pinned = val;
                      });
                    },
                    value: _pinned,
                    activeColor: Colors.orange,
                    trackColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 30, // Rowの高さを調整する
            child: Row(
              children: [
                const Text(
                  'BS Digital',
                  style: TextStyle(color: Colors.white),
                ),
                //const SizedBox(width: 10),
                Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    onChanged: (bool val) {
                      setState(() {
                        _snap = val;
                        // Snapping only applies when the app bar is floating.
                        //_floating = _floating || _snap;
                      });
                    },
                    value: _snap,
                    activeColor: Colors.orange,
                    trackColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 30, // Rowの高さを調整する
            child: Row(
              children: [
                const Text(
                  'Unused   ',
                  style: TextStyle(color: Colors.grey),
                ),
                //const SizedBox(width: 10),
                Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    onChanged: (bool val) {
                      setState(() {
                        //_floating = val || _pinned;
                        //_snap = _snap && _floating;
                      });
                    },
                    value: _floating,
                    activeColor: Colors.orange,
                    trackColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      Column(
        children: List.generate(2, (rowIndex) {
          return Row(
            children: List.generate(5, (columnIndex) {
              final index = rowIndex * 5 + columnIndex;
              return Column(children: [
                const SizedBox(width: 110), // ボタンの間の間隔を設定
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonStates[index]
                        ? Colors.amber[900]
                        : Colors.grey, // ボタンの色を変更Colors.grey, //ボタンの背景色
                  ).merge(
                    ButtonStyle(
                      minimumSize: MaterialStateProperty.all(
                          const Size(100, 30)), // ボタンの最小サイズを指定
                      // 他のButtonStyle属性も追加できます
                    ),
                  ),
                  onLongPress: () {
                    editDialog(index);
                  },
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < buttonStates.length; i++) {
                        if (i == index) {
                          // 押されたボタンの色を変更
                          buttonStates[i] = true;
                        } else {
                          // 既に押されているボタンの色を元の色に戻す
                          buttonStates[i] = false;
                        }
                      }
                      keyWord = data[index]["SearchWard"];
                      currentPage = 1;
                      scrapePage(currentPage);
                      //returnMap = _fetchStockTv(data[index]["SearchWard"]);
                    });
                  },
                  child: Text(
                    data[index]["ButtonName"],
                    style: data[index]["SearchWard"] == ""
                        ? const TextStyle(color: Colors.black)
                        : const TextStyle(color: Colors.white),
                  ),
                ),
              ]);
            }),
          );
        }),
      ),
    ]);
    //);
  }
*/
  Container search(dynamic anystock) {
    TextEditingController searchtextEditingController = TextEditingController();
    return Container(
      // width: 10.0,
      margin: const EdgeInsets.only(
          top: 10.0, left: 10.0, right: 10.0, bottom: 10.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center, //上下
        children: [
          SizedBox(
            width: 200,
            //height: 50,
            //color: Colors.red,
            child: TextField(
              controller: searchtextEditingController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.yellow,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.orange,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),

                //hintText: '検索ワード',
                labelText: 'any Search word',
                labelStyle: TextStyle(
                  color: Colors.orange, // テキストの色を変更
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.yellow,
                ),
              ),
              onSubmitted: (String value) async {
                searchtextEditingController.clear(); // テキストを消去
                setState(() {
                  //keyWord = value;
                  idol = value;
                  //scrapePage(0);
                  scrapePageGguid(0);
                  //scrapedData = _fetchStockTv(value);
                });
              },
            ),
          ),
          const SizedBox(
            width: 0,
          ),
          SizedBox(
              width: 400,
              //height: 50,
              //color: Colors.grey,
              child: Row(
                children: [
                  const Text('Number of Detected Pages:  ',
                      style:
                          TextStyle(color: Colors.greenAccent, fontSize: 16)),
                  ElevatedButton(
                    onPressed: () {
                      goToPreviousPage();
                      const Text('Previou Page');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // ボタンの背景色
                      foregroundColor: Colors.black, // テキストの色
                    ),
                    child: const Icon(Icons.arrow_left),
                  ),
                  SizedBox(
                    width: 70.0,
                    child: Text(
                      fraction,
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 20),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // advanceボタンが押されたときの処理
                      goToNextPage();
                      const Text('Next Page');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent, // ボタンの背景色
                      foregroundColor: Colors.black, // テキストの色
                    ),
                    child: const Icon(Icons.arrow_right), //Text('Button 2'),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  listView(dynamic anystock) => ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: anystock!.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
            margin: const EdgeInsets.only(
                top: 0.0, left: 10.0, right: 10.0, bottom: 10.0),
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade800,
                ],
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
            child: Row(children: <Widget>[
              Expanded(
                flex: 0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    fixedSize: const Size(50, 50),
                    backgroundColor: Colors.amber[900], //ボタンの背景色
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    //runCommand();
                    //_asyncEditDialog(context, index);
                  },
                  onLongPress: () {
                    //alertDialog(index);
                  },
                  child: Text((index + 1).toString(),
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                        fontFamily: 'NotoSansJP',
                      )),
                ),
              ),

              //SizedBox(width: 15.0,),
              Expanded(
                //flex: 6,
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anystock[index]["Title"],
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.grey,
                        fontFamily: 'NoteSansJP',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          anystock[index]["Date"],
                          style: const TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 15.0,
                              color: Colors.blue),
                        ),
                        Text(
                          anystock[index]["Day"],
                          style: const TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 15.0,
                              color: Colors.blue),
                        ),
                        Text(
                          anystock[index]["StartTime"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.yellow),
                        ),
                        Text(
                          anystock[index]["From"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.yellow),
                        ),
                        Text(
                          anystock[index]["EndTime"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.yellow),
                        ),
                        Text(
                          anystock[index]["Airtime"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.orange),
                        ),
                        Text(
                          anystock[index]["Channels"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.red),
                        ),
                        Text(
                          anystock[index]["Channels2"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              //SizedBox(width: 50.0,),
            ]));
      });

  listViewGguid(dynamic anystock) => ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: anystock!.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
            margin: const EdgeInsets.only(
                top: 0.0, left: 10.0, right: 10.0, bottom: 10.0),
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade800,
                ],
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
            child: Row(children: <Widget>[
              Expanded(
                flex: 0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    fixedSize: const Size(50, 50),
                    backgroundColor: Colors.amber[900], //ボタンの背景色
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    //runCommand();
                    //_asyncEditDialog(context, index);
                  },
                  onLongPress: () {
                    //alertDialog(index);
                  },
                  child: Text((index + 1).toString(),
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                        fontFamily: 'NotoSansJP',
                      )),
                ),
              ),

              //SizedBox(width: 15.0,),
              Expanded(
                //flex: 6,
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anystock[index]["Title"],
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.grey,
                        fontFamily: 'NoteSansJP',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          anystock[index]["Date"],
                          style: const TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 15.0,
                              color: Colors.blue),
                        ),
                        Text(
                          anystock[index]["Day"],
                          style: const TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: 15.0,
                              color: Colors.blue),
                        ),
                        Text(
                          anystock[index]["StartTime"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.yellow),
                        ),
                        Text(
                          anystock[index]["Channels"],
                          style: const TextStyle(
                              fontFamily: 'NoteSansJP',
                              //fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: Colors.red),
                        ),
                        
                      ],
                    ),
                  ],
                ),
              ),
              //SizedBox(width: 50.0,),
            ]));
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: scrapedData, //returnMap,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          List<Map<String, dynamic>> dataList = snapshot.data!;
          return Container(
            //width: 1800,
            width: MediaQuery.of(context).size.width * 1.5,
            height: 1500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 255, 251, 2),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),
                //Expanded(
                Container(
                  //width: 750,
                  width: MediaQuery.of(context).size.width * 0.55,
                  // The height is not needed as it will be automatically adjusted by Expanded
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black,
                  ),
                  child: buttonView1(stockdataList),
                ),
                //),
                //Expanded(
                Container(
                  margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  //width: 750,
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 50.0,
                  // The height is not needed as it will be automatically adjusted by Expanded
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black,
                  ),
                  child: search(dataList.length),
                ),
                //),
                Expanded(
                  child: Container(
                    //width: 750,
                    width: MediaQuery.of(context).size.width * 0.5,
                    //height: 100,
                    // The height is not needed as it will be automatically adjusted by Expanded
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.black,
                    ),
                    //child: listView(dataList),
                    child: listViewGguid(dataList),
                  ),
                ),
                //Expanded(
                SizedBox(
                  //width: 750.0,
                  width: MediaQuery.of(context).size.width * 0.9,
                  // The height is not needed as it will be automatically adjusted by Expanded
                  child: Text(systemState),
                ),
                //),
                //Expanded(
                SizedBox(
                  //width: 750.0,
                  width: MediaQuery.of(context).size.width * 0.9,
                  // The height is not needed as it will be automatically adjusted by Expanded
                  child: Text(outputState),
                ),
                //),
              ],
            ),
          );
        },
      ),
      //),
    );
  }
}
