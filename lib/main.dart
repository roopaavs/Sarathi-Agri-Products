import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

void main() => runApp(SarathiApp());

class SarathiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class DBHelper {
  static Database? _db;
  static Future<Database> getDB() async {
    if(_db!=null) return _db!;
    String p = join(await getDatabasesPath(), 'sarathi.db');
    _db = await openDatabase(p, version:1, onCreate:(db,v) async{
      await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, product TEXT, qty REAL, price REAL, total REAL, date TEXT)');
      await db.execute('CREATE TABLE khata(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, amount REAL, type TEXT, date TEXT)');
      await db.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, note TEXT, date TEXT)');
    });
    return _db!;
  }
}

class Home extends StatefulWidget { @override State<Home> createState()=>_HomeS(); }
class _HomeS extends State<Home> {
  int idx=0;
  @override Widget build(BuildContext context){
    return Scaffold(
      body:[Bill(),Khata(),Exp()][idx],
      bottomNavigationBar: BottomNavigationBar(currentIndex:idx, onTap:(v)=>setState(()=>idx=v), selectedItemColor: Colors.green, items:[
        BottomNavigationBarItem(icon:Icon(Icons.receipt),label:'Billing'),
        BottomNavigationBarItem(icon:Icon(Icons.book),label:'Khata'),
        BottomNavigationBarItem(icon:Icon(Icons.local_gas_station),label:'Expense'),
      ]),
    );
  }
}

class Bill extends StatefulWidget { @override State<Bill> createState()=>_BillS(); }
class _BillS extends State<Bill>{
  final n=TextEditingController(); final q=TextEditingController(); final p=TextEditingController();
  String prod='Silage'; List<Map> bills=[];
  @override void initState(){super.initState(); load();}
  load() async{ final db=await DBHelper.getDB(); final r=await db.query('bills',orderBy:'id DESC'); setState(()=>bills=r); }
  pick() async{ if(await FlutterContacts.requestPermission()){ final c=await FlutterContacts.openExternalPick(); if(c!=null) setState(()=>n.text=c.displayName); } }
  save() async{ double qq=double.tryParse(q.text)??0; double pp=double.tryParse(p.text)??0; final db=await DBHelper.getDB(); await db.insert('bills',{'name':n.text,'product':prod,'qty':qq,'price':pp,'total':qq*pp,'date':DateTime.now().toString()}); n.clear();q.clear();p.clear(); load(); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:Text('Sarathi - Billing'),backgroundColor:Colors.green),body:ListView(padding:EdgeInsets.all(12),children:[
      Row(children:[Expanded(child:TextField(controller:n,decoration:InputDecoration(labelText:'Customer Name',border:OutlineInputBorder()))),IconButton(icon:Icon(Icons.contacts),onPressed:pick)]),
      SizedBox(height:8),DropdownButtonFormField(value:prod,items:['Silage','Corn','Fodder'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>prod=v!)),
      SizedBox(height:8),Row(children:[Expanded(child:TextField(controller:q,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Qty Kg',border:OutlineInputBorder()))),SizedBox(width:8),Expanded(child:TextField(controller:p,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Price/Kg',border:OutlineInputBorder())))]),
      SizedBox(height:10),ElevatedButton(onPressed:save,child:Text('Save Bill'),style:ElevatedButton.styleFrom(backgroundColor:Colors.green,minimumSize:Size(double.infinity,45))),
      Divider(),...bills.map((e)=>Card(child:ListTile(title:Text("${e['name']} - ${e['product']}"),subtitle:Text("${e['qty']} Kg x ${e['price']} = ${e['total']}"),trailing:Text(e['date'].toString().substring(0,10))))).toList()
    ]));
  }
}

class Khata extends StatefulWidget { @override State<Khata> createState()=>_KhataS(); }
class _KhataS extends State<Khata>{
  List<Map> list=[];
  @override void initState(){super.initState(); load();}
  load() async{ final db=await DBHelper.getDB(); final r=await db.query('khata',orderBy:'id DESC'); setState(()=>list=r); }
  add(String type) async{
    final nc=TextEditingController(); final ac=TextEditingController();
    showDialog(context:context,builder:(_)=>AlertDialog(title:Text('$type'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:nc,decoration:InputDecoration(labelText:'Name')),TextField(controller:ac,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Amount'))]),actions:[TextButton(onPressed:()async{ final db=await DBHelper.getDB(); await db.insert('khata',{'name':nc.text,'amount':double.tryParse(ac.text)??0,'type':type,'date':DateTime.now().toString()}); Navigator.pop(context); load(); },child:Text('Save'))]));
  }
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:Text('Khata Book'),backgroundColor:Colors.green),body:ListView.builder(itemCount:list.length,itemBuilder:(_,i)=>Card(color:list[i]['type']=='Credit'?Colors.green[50]:Colors.red[50],child:ListTile(title:Text(list[i]['name']),subtitle:Text("${list[i]['type']} - ${list[i]['date'].toString().substring(0,10)}"),trailing:Text("Rs ${list[i]['amount']}",style:TextStyle(fontWeight:FontWeight.bold))))),floatingActionButton:Row(mainAxisAlignment:MainAxisAlignment.end,children:[FloatingActionButton.extended(onPressed:()=>add('Credit'),label:Text('Credit'),icon:Icon(Icons.add)),SizedBox(width:8),FloatingActionButton.extended(onPressed:()=>add('Debit'),label:Text('Debit'),icon:Icon(Icons.remove),backgroundColor:Colors.red)]));
  }
}

class Exp extends StatefulWidget { @override State<Exp> createState()=>_ExpS(); }
class _ExpS extends State<Exp>{
  List<Map> list=[]; String cat='Labor';
  @override void initState(){super.initState(); load();}
  load() async{ final db=await DBHelper.getDB(); final r=await db.query('expenses',orderBy:'id DESC'); setState(()=>list=r); }
  add() async{
    final ac=TextEditingController(); final nc=TextEditingController();
    showDialog(context:context,builder:(_)=>AlertDialog(title:Text('Add Expense'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField(value:cat,items:['Labor','Import','Petrol'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>cat=v!),decoration:InputDecoration(labelText:'Category')),TextField(controller:ac,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Amount')),TextField(controller:nc,decoration:InputDecoration(labelText:'Note'))]),actions:[TextButton(onPressed:()async{ final db=await DBHelper.getDB(); await db.insert('expenses',{'category':cat,'amount':double.tryParse(ac.text)??0,'note':nc.text,'date':DateTime.now().toString()}); Navigator.pop(context); load(); },child:Text('Save'))]));
  }
  @override Widget build(BuildContext context){
    double l=list.where((e)=>e['category']=='Labor').fold(0.0,(a,b)=>a+(b['amount'] as double));
    double im=list.where((e)=>e['category']=='Import').fold(0.0,(a,b)=>a+(b['amount'] as double));
    double pe=list.where((e)=>e['category']=='Petrol').fold(0.0,(a,b)=>a+(b['amount'] as double));
    return Scaffold(appBar:AppBar(title:Text('Expense - Labor/Import/Petrol'),backgroundColor:Colors.green),body:Column(children:[Card(child:Padding(padding:EdgeInsets.all(10),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[Text('Labor: $l'),Text('Import: $im'),Text('Petrol: $pe')]))),Expanded(child:ListView.builder(itemCount:list.length,itemBuilder:(_,i)=>ListTile(title:Text("${list[i]['category']} - Rs ${list[i]['amount']}"),subtitle:Text("${list[i]['note']} - ${list[i]['date'].toString().substring(0,10)}"))))]),floatingActionButton:FloatingActionButton(onPressed:add,child:Icon(Icons.add)));
  }
}
