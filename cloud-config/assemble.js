var fs = require('fs'),
  yaml = require('js-yaml'),
  json2yaml = require('json2yaml');

var configSets = {
  master: {},
  base: {},
  node: {}
};

var varData = fs.readFileSync(__dirname + '/../terraform.tfvars').toString();
varData.split("\n").forEach(function (line) {
  var match = line.match(/^(.+?) = "(.+?)"$/)
  process.env[match[1]] = match[2];
});

var baseTemplates = fs.readdirSync(__dirname + '/src/base');
baseTemplates.map(compileTemplate);

function compileTemplate (templatePath) {
  var loadPath = __dirname + '/src/base/' + templatePath;
  var data = yaml.safeLoad(fs.readFileSync(loadPath));
  var config = configSets[templatePath.split('.').unshift()];

  data['write-files'] = data['write-files'].map(function (file) {
    if (file.file) {
      var fileData = fs.readFileSync(__dirname + '/src/files/' + file.file).toString();
      delete file.file;
      file.content = fileData;
    } else if (file.secret) {
      var fileData = fs.readFileSync(__dirname + '/src/secrets/' + file.secret).toString();
      fileData = fileData.replace(/\$\{(.+?)\}/g, function (str, match) {
        return process.env[match];
      });
      fileData = JSON.parse(fileData);
      for (key in fileData.data) {
        fileData.data[key] = new Buffer(fileData.data[key]).toString('base64');
      }
      delete file.secret;
      file.permissions = '0600';
      file.content = JSON.stringify(fileData)
    }

    return file;
  });

  data.coreos.units = data.coreos.units.map(function (unit) {
    try {
      var fileData = fs.readFileSync(__dirname + '/src/files/' + unit.name).toString();
      unit.content = fileData;
    } catch (e) {}

    return unit;
  });

  fs.writeFileSync(__dirname + '/compiled/' + templatePath, "#cloud-config\n\n" + json2yaml.stringify(data));
};