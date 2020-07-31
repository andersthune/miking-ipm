let topComment =
`/**
* Initializes the DFA object.
* This file was automatically generated from src/visual/boot.js.
*/\n`;

const { exec } = require('child_process');



var fs = require('fs');
//Get the file that is being edited
var myArgs = process.argv.slice(2);
console.log('myArgs: ', myArgs);

var open_browser = true
var sourceFile = ""

function process_arg(arg) {
    switch (arg) {
    case '--no-open':
        open_browser = false;
        break;
    default:
        sourceFile = arg;
    }
}

myArgs.map(process_arg);

//Specify the path to the miking executable in this variable:
//Compile the code
function compile_fun() {
    exec("mi " + sourceFile + ' > ' + __dirname +'/webpage/js/data-source.js', (error, stdout, stderr) => {
    if (error) {
        fs.readFile(__dirname +'/webpage/js/data-source.js', function(err, buf) {
        fs.writeFile(__dirname +'/webpage/js/data-source.js',
            "let inputModel = '" + buf.toString().replace(/(\r\n|\n|\r)/gm, "")
            + "';" , function (err) {if (err) return console.log(err);});});return;}
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    });
}



compile_fun();


// Inital render of graph

fs.watchFile(sourceFile, { interval: 1000 }, (curr, prev) => {
    console.log(`${sourceFile} file Changed`);
    //Re-extract the AST -> JSON from the MCore model to a JSON file and recompile the JS
    compile_fun();

});


//This is being displayed on the browser: use index.html for the moment
var bs = require('browser-sync').create();


bs.init({
    watch: true,
    port: 3000,
    notify: false,
    server: __dirname + '/webpage',
    open: open_browser
});

bs.reload();
