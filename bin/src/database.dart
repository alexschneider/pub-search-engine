import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:redis/redis.dart';

const connectionString = 'localhost:6379';
final Future redisClient = (new RedisConnection()).connect('localhost', 6379);

Future populateDatabase() {
  return redisClient.then((Command command) {
    return command.get('pub:lastUpdatedTimestamp').then((res) {
      if (res == null || true) {
        return beginUpdate(command).then((_) =>
          command.set('pub:lastUpdatedTimestamp', (new DateTime.now()).millisecondsSinceEpoch.toString()));
      }
    });
  });
}

Future beginUpdate(Command command) {
  print('getting package list');
  return getPage(1).then((val) {
    print('getting package metadata');
    var client = new HttpClient();
    client.maxConnectionsPerHost = 10;
    return Future.wait(val.map((package) {
      print('getting metadata for $package');
      return client.getUrl(Uri.parse(package)).then((HttpClientRequest req) {
        return req.close();
      }).then((HttpClientResponse res) {
        print('finished getting metadata for $package');
        return res.transform(UTF8.decoder).transform(JSON.decoder).first;
      });
    }));
  }).then((packages) {
    print('here we go!');
    command.multi().then((Transaction trans) {
      trans.send_object(['FLUSHDB']);
      for (var package in packages) {
        package['uploaders'].forEach((uploader) {
          trans.send_object(['SADD', 'pub:package:${package['name']}:uploaders', uploader]);
        });
        package['versions'].forEach((version) {
          trans.send_object(['SADD', 'pub:package:${package['name']}:versions', version]);
        });
        package['uploaders'].forEach((uploader) {
          trans.send_object(['SADD', 'pub:uploader:$uploader', package['name']]);
        });
      };

      //trans.set('pub:lastUpdatedTimestamp', (new DateTime.now()).millisecondsSinceEpoch.toString());

      return trans.exec();
    });
  });
}

Future<List<String>> getPage(int page) {
  var client = new HttpClient();
  return client.getUrl(Uri.parse('https://pub.dartlang.org/packages.json?page=$page')).then((HttpClientRequest req) {
    return req.close();
  }).then((HttpClientResponse res) {
    return res.transform(UTF8.decoder).transform(JSON.decoder).first.then((contents) {
      var transformation = new Future.value(contents['packages']);
      if (contents['next'] != null) {
        transformation = transformation.then((List val) {
          return getPage(page + 1).then((accumulatedVal) {
            var accum = val.toList();
            accum.addAll(accumulatedVal);
            return accum;
          });
        });
      }
      return transformation;
    });
  });
}