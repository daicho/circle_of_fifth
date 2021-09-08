// 円の位置
final float c0 = 0.99;
final float c1 = 0.79;
final float c2 = 0.59;
final float c3 = 0.39;

// コードネーム
String[] codes = {"C", "G", "D", "A", "E", "B", "G", "D", "A", "E", "B", "F"};

void setup() {
  // ウィンドウ設定
  size(640, 640);
  surface.setResizable(true);
  
  // 描画設定
  strokeWeight(0.005);
  strokeCap(SQUARE);
  ellipseMode(RADIUS);
  
  // フォント
  PFont font = createFont("游ゴシック Regular", 9);
  textFont(font);
  textAlign(CENTER, CENTER);
}

void draw() {
  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);
  
  background(255);
  
  // 円を描画
  stroke(0);
  fill(255);
  ellipse(0, 0, c0, c0);
  ellipse(0, 0, c1, c1);
  ellipse(0, 0, c2, c2);
  ellipse(0, 0, c3, c3);
  
  // 線を描画
  pushMatrix();
  rotate(TWO_PI / 24);
  
  for (int i = 0; i < 12; i++) {
    line(0, c0, 0, c3);
    rotate(TWO_PI / 12);
  }
  
  popMatrix();
  
  // コードを描画
  for (int i = 0; i < 12; i++) {
    pushMatrix();
    
    translate((c0 + c1) / 2 * sin(TWO_PI / 12 * i), (c0 + c1) / 2 * -cos(TWO_PI / 12 * i));
    scale(0.01);
    translate(-0.7, -2.2);
    
    fill(0);
    text(codes[i], 0, 0);
    
    popMatrix();
  }
}
