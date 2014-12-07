import 'package:redstone/server.dart' as app;
import 'src/mustache.dart';
import 'src/database.dart';
import 'package:shelf_static/shelf_static.dart';

@app.Route('/', responseType: 'text/html')
index() => mustache('index.mustache');

@app.Route('/browse', responseType: 'text/html')
browse() => "YOU MADE IT!";



void main() {
  app.setupConsoleLog();
  app.setShelfHandler(createStaticHandler('../web/serve', serveFilesOutsidePath: true));
  app.start();
  populateDatabase();
}



