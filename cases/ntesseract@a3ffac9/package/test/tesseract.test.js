'use strict';

const assert = require('chai').assert;
const path = require('path');
const tesseract = require('../lib/tesseract');


describe('process', function () {

  it('should parse options to command', function () {
    const options = {
      binary: 'tesseract-ocr',
      l: 'chs',
      psm: '9',
      output: '/tmp/tesseract',
      '--tessdata-dir': './tessdata',
      '--user-words': './userwords',
      '--user-patterns': './userpatterns'
    };
    const command = 'tesseract-ocr test.png /tmp/tesseract -l chs --psm 9  --tessdata-dir ./tessdata --user-words ./userwords --user-patterns ./userpatterns';
    assert.equal(tesseract.command('test.png', options), command);
  });

  it('should return the string "node-tesseract"', function (done) {
    const image = path.join(__dirname, 'fixtures', 'test.png');
    tesseract.process(image, function (err, text) {
      assert.notOk(err);
      assert.equal(text.trim(), 'node-tesseract');
      done();
    });

  })
});

