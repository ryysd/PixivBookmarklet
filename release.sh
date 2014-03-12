rm -rf ./release
mkdir release
mkdir release/css
mkdir release/src
mkdir release/icons

cp css/btn-design.css release/css/
cp src/jquery.min.js release/src/
cp src/download.js release/src/
cp src/pixiv-loader.js release/src/

cp manifest.json release/

cp icons/icon.png release/icons

zip -r pic.zip release
