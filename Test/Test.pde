/**
* ADSR controlled by GUI
*
* @author aa_debdeb
* @date 2016/10/31
*/

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import controlP5.*;

Minim minim;
AudioOutput out;
ControlP5 cp5;

float attack, decay, sustain, release;

void setup(){
  size(400, 300);
  minim = new Minim(this);
  out = minim.getLineOut();
  cp5 = new ControlP5(this);
  float radius = 30;
  cp5.addKnob("attack")
     .setRange(0, 3.0)
     .setValue(1.5)
     .setPosition(50 - radius, height / 2 - radius)
     .setRadius(radius)
     .setDragDirection(Knob.VERTICAL); 
  cp5.addKnob("decay")
     .setRange(0, 3.0)
     .setValue(1.5)
     .setPosition(150 - radius, height / 2 - radius)
     .setRadius(radius)
     .setDragDirection(Knob.VERTICAL); 
  cp5.addKnob("sustain")
     .setRange(0, 1.0)
     .setValue(0.5)
     .setPosition(250 - radius, height / 2 - radius)
     .setRadius(radius)
     .setDragDirection(Knob.VERTICAL); 
  cp5.addKnob("release")
     .setRange(0, 3.0)
     .setValue(1.5)
     .setPosition(350 - radius, height / 2 - radius)
     .setRadius(radius)
     .setDragDirection(Knob.VERTICAL); 
}

void keyPressed(){
  out.playNote(0.0, 0.3, new MyInstrument());
}

void draw(){

}

class MyInstrument implements Instrument {
  Oscil osc;
  ADSR adsr;
  MyInstrument(){
    osc = new Oscil(random(200, 800), 0.5, Waves.TRIANGLE);
    adsr = new ADSR(0.5, attack, decay, sustain, release);
    osc.patch(adsr);
  }
  
  void noteOn(float dur){
    adsr.noteOn();
    adsr.patch(out);
  }
  
  void noteOff(){
    adsr.unpatchAfterRelease(out);
    adsr.noteOff();
  }
}
