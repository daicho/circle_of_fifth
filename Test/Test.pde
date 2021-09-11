/*
* sample04
*/

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

Minim minim;
AudioOutput out;

void setup(){
  size(512, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
}

void mousePressed(){
  out.playNote(0.0, 0.5, new MyInstrument(Frequency.ofPitch("C4").asHz(), 0.5));
  out.playNote(0.5, 1.0, new MyInstrument(Frequency.ofPitch("D4").asHz(), 0.75));
  out.playNote(1.5, 1.5, new MyInstrument(Frequency.ofPitch("E4").asHz(), 1.0));
}

void draw(){
  background(0);
  stroke(255);
  strokeWeight(1);
  for(int i = 0; i < out.bufferSize() - 1; i++){
    line(i, 50 + out.left.get(i) * 50, i + 1, 50 + out.left.get(i + 1) * 50);
    line(i, 150 + out.right.get(i) * 50, i + 1, 150 + out.right.get(i + 1) * 50);
  }
}

class MyInstrument implements Instrument{
  Oscil oscil;
  MyInstrument(float frequency, float amplitude){
    oscil = new Oscil(frequency, amplitude, Waves.SINE);
  }
  
  void noteOn(float duration){
    oscil.patch(out);
  }
  
  void noteOff(){
    oscil.unpatch(out);
  } 
}
