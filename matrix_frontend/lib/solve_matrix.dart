import 'package:flutter/material.dart';

class SolveMatrix extends StatefulWidget {
  List<List<int>> matrix;

  SolveMatrix({this.matrix});
  @override
  _SolveMatrixState createState() => _SolveMatrixState();
}

class _SolveMatrixState extends State<SolveMatrix> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: double.infinity,
          ),
          Container(
            child: RaisedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Return"),
            ),
          ),
          Container(
              padding: EdgeInsets.all(40),
              child: MatrixWidget(matrix: widget.matrix)),
        ],
      ),
    );
  }
}

class MatrixWidget extends StatefulWidget {
  List<List<int>> matrix;

  MatrixWidget({this.matrix});
  @override
  _MatrixWidgetState createState() => _MatrixWidgetState();
}

class _MatrixWidgetState extends State<MatrixWidget> {
  @override
  Widget build(BuildContext context) {
    int height = widget.matrix.length;
    int width = widget.matrix[0].length;

    return Column(
      children: List.generate(
          height,
          (i) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    width, (j) => MatrixElement(value: widget.matrix[i][j])),
              )),
    );
  }
}

class MatrixElement extends StatefulWidget {
  const MatrixElement({
    @required this.value,
  });

  final int value;

  @override
  _MatrixElementState createState() => _MatrixElementState();
}

class _MatrixElementState extends State<MatrixElement> {
  int value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      child: FlatButton(
        onPressed: () {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(_changeValue());
        },
        child: Text(
          '$value',
          style: TextStyle(fontSize: 32),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  SnackBar _changeValue() {
    return SnackBar(
        content: Container(
          width: double.infinity,
          height: 200,
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                      value = index;
                    });
                  },
                  child: Text(
                    "$index",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
        ),
        duration: Duration(seconds: 5));
  }
}
