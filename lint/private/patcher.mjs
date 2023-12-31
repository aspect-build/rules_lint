import childProcess from "node:child_process";
import path from "node:path";
import fs from "node:fs";
import os from "node:os";

async function sync(src, dst, subdir, filesToDiff) {
  // Symlink the remainder of the src to dst
  const files = (await fs.promises.readdir(path.join(src, subdir))).map((f) =>
    path.join(subdir, f)
  );
  for (const f of files) {
    const srcF = path.join(src, f);
    const dstF = path.join(dst, f);
    let symlink = true;
    for (const d of filesToDiff) {
      if (f === d) {
        // console.error(`copying ${f}`);
        await fs.promises.mkdir(path.dirname(dstF), { recursive: true });
        fs.writeFileSync(dstF, fs.readFileSync(srcF));
        await fs.promises.chmod(dstF, "600");
        symlink = false;
        break;
      } else if (d.startsWith(f)) {
        // console.error(`entering ${f}`);
        await sync(src, dst, f, filesToDiff);
        symlink = false;
        break;
      }
    }
    if (symlink) {
      //   console.error(`symlinking ${f}`);
      await fs.promises.mkdir(path.dirname(dstF), { recursive: true });
      await fs.promises.symlink(srcF, dstF);
    }
  }
}

async function main(args, sandbox) {
  // console.error("cwd", process.cwd());
  // console.error("sandbox", sandbox);
  const config = JSON.parse(await fs.promises.readFile(args[0]));
  // console.error("config", JSON.stringify(config, null, 2));
  // console.error(`syncing ${process.cwd()} to ${sandbox}`);
  await sync(process.cwd(), sandbox, ".", config.files_to_diff);

  // console.error(`spawning linter: ${config.linter} ${config.args.join(" ")} and env ${JSON.stringify(config.env)}`);
  const ret = childProcess.spawnSync(config.linter, config.args, {
    stdio: "inherit",
    cwd: sandbox,
    env: config.env || {},
  });

  if (ret.error) {
    console.error(ret.error);
    process.exit(1);
  }

  const diffOut = fs.createWriteStream(config.output);

  for (const f of config.files_to_diff) {
    const origF = path.join(process.cwd(), f);
    const newF = path.join(sandbox, f);
    // console.error(`diffing ${origF} to ${newF}`);
    const results = childProcess.spawnSync("diff", ["-U8", origF, newF], {
      encoding: "utf8",
    });
    // if (results.stdout) {
    //   console.error(results.stdout);
    // }
    diffOut.write(results.stdout);
    if (results.error) {
      console.error(results.error);
    }
  }

  diffOut.close();
}

(async () => {
  let sandbox;
  try {
    sandbox = path.join(
      await fs.promises.mkdtemp(path.join(os.tmpdir(), "rules_lint_patcher-")),
      process.env.JS_BINARY__WORKSPACE
    );
    await main(process.argv.slice(2), sandbox);
  } catch (e) {
    console.error(e);
    process.exit(1);
  } finally {
    try {
      if (sandbox) {
        await fs.promises.rm(sandbox, { recursive: true });
      }
    } catch (e) {
      console.error(
        `An error has occurred while removing the sandbox folder at ${sandbox}. Error: ${e}`
      );
    }
  }
})();
