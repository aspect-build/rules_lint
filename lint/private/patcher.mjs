import childProcess from 'child_process';
import path from 'path';
import fs from 'fs';
import os from 'os';

const node = process.argv[0];
const wrapper = process.argv[1];
const linterArgs = process.argv.slice(2);

const filesToLint = fs.readFileSync(process.env.FILES_TO_LINT_PATH).toString().replace(/\n+$/, '').split('\n');

const tmpDirPath = fs.mkdtempSync("/tmp/");

const tmpFiles = [];
for (const f of filesToLint) {
    const destF = path.join(tmpDirPath, f);
    fs.mkdirSync(path.dirname(destF), {recursive: true});
    fs.cpSync(f, destF);
    fs.chmodSync(destF, "600");
    tmpFiles.push(destF);
}

const filesIndex = linterArgs.indexOf("$$FILES");
linterArgs.splice(filesIndex, 1, ...tmpFiles);

const linterPath = path.join(process.env["JS_BINARY__EXECROOT"], process.env["LINTER_PATH"]);
const newEnv = {...process.env};
delete newEnv["JS_BINARY__EXIT_CODE_OUTPUT_FILE"];

const ret = childProcess.spawnSync(linterPath, linterArgs, {
    stdio: "inherit",
    env: newEnv,
});

if (ret.error) {
    console.log(error);
    process.exit(1);
}

const diffOut = fs.createWriteStream(process.env["PATCH_PATH"]);

for (let i = 0; i < filesToLint.length; i++) {
    const origF = filesToLint[i];
    const newF = tmpFiles[i];
    console.log(origF, newF);
    const results = childProcess.spawnSync("diff", ["-U8", origF, newF], {
        encoding: 'utf8',
    });
    diffOut.write(results.stdout);
    if (results.error) {
        console.error(results.error);
    }
}

diffOut.close();