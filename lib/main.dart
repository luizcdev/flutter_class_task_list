import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() {

  runApp(MaterialApp(
    home: Home(),
  ));

}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  void _addToDo() {

    final Map<String, dynamic> _newToDo = Map();
    _newToDo["title"] = _toDoController.text;
    _newToDo["ok"] = false;

    setState(() {
      _toDoList.add(_newToDo);
      _toDoController.clear();
    });
    _saveData();

  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;

  }


  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(child:  TextField(
                  controller: _toDoController,
                  decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blueAccent,
                      textStyle: TextStyle(color: Colors.blueAccent)
                    ),
                    onPressed: _addToDo,
                    child: Text("ADD"),
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: _buildItem
              ))
          ),
        ]
      )
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white)
          ),
        ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _toDoList[index]["ok"] = checked;
          });

          _saveData();
        },
      ),
      onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPosition = index;
            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
                content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
                action: SnackBarAction(label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                },),
              duration: Duration(seconds: 2),
            );

            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json}");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {

    try {

      final file = await _getFile();
      return file.readAsString();

    } catch(e) {
      return null;
    }

  }
}