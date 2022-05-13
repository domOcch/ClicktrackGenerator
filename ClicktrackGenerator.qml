import QtQuick 2.0
import MuseScore 3.0
import QtQuick.Layouts 1
import QtQuick.Controls.Styles 1.3
import QtQuick.Controls 1.3
import QtQuick.Dialogs 1.2
// measureproperties.h, measure.h (libmscore)
// have to use the plugin api accessible features
MuseScore {
      menuPath: "Plugins.ClicktrackGenerator"
      description: "Automatically generate click track"
      version: "1.0"
      onRun: {   
            /* Useful info
            * use timsigActual.denominator or .numerator to get time sig
            * tempo is represented as x/60, where is 60 quarter note bpm
            * velocity is how accents are created; note property (how to access?)
            * metronome subdivides  compound time below dotted quarter = 60 aka quarter = 90 aka 1.5
            * dotted quarter tempo x 3 / 2 = quarter tempo
            * NEED TO LEARN ABOUT TICKS, what do you do about mid-bar tempo changes?
            
            enum class BeatType : char {
      DOWNBEAT,               // 1st beat of measure (rtick == 0)
      COMPOUND_STRESSED,      // e.g. eighth-note number 7 in 12/8
      SIMPLE_STRESSED,        // e.g. beat 3 in 4/4
      COMPOUND_UNSTRESSED,    // e.g. eighth-note numbers 4 or 10 in 12/8
      SIMPLE_UNSTRESSED,      // "offbeat" e.g. beat 2 and 4 in 4/4 (i.e. the denominator unit)
      COMPOUND_SUBBEAT,       // e.g. any other eighth-note in 12/8 (i.e. the denominator unit)
      SUBBEAT                 // does not fall on a beat
      };
            */    
            // var visible = true;
            // var subdivide = false;

            curScore.appendPart("wood-blocks")
            // ask user for visible or invisible
            // curScore.parts[curScore.parts.length - 1].show = false;
            
            // set up cursor
            var cursor = curScore.newCursor();
            cursor.rewind(0); //set position at beginning of score
            cursor.staffIdx = curScore.nstaves - 1; //move cursor to last line, staves start at 0

            // populate click track part with notes
            insertNotes(cursor);
            
            // set velocities
            cursor.rewind(0);            
            setVelocities(cursor)
            
            cursor.rewind(0);
            var tempoElement = newElement(Element.MEASURE);
            cursor.add(tempoElement);
            cursor.add(Element.REST);
            Qt.quit()
      }
      
      // use boolean for CompoundNoSubdivison, eliminate need for functions
      function insertNotes(cursor){
            var numMeasures = curScore.nmeasures;           

            for (var i = 0; i < numMeasures; i++){
                  var numerator = cursor.measure.timesigActual.numerator;
                  var denominator = cursor.measure.timesigActual.denominator;
                  
                  if (numerator % 3 == 0 && numerator > 3){
                  // add way to force subdivision
                        if (cursor.tempo >= 12.0 / denominator){
                              addCompoundNoSubdivision(cursor, numerator, denominator);
                        }else{
                              addCompoundSubdivision(cursor, numerator, denominator);
                        } 
                  }else{
                        addSimpleOrAsymetrical(cursor, numerator, denominator);
                  }
                        
                  
                    
            }
      }
      
      function addCompoundSubdivision(cursor, numerator, denominator){
            cursor.setDuration(1, denominator);
            cursor.addNote(76,false);        
            cursor.addNote(77,true);
            
            var notesToAdd = numerator - 1;
            
            for(var j = 0;j < notesToAdd; j++){
                cursor.addNote(77 ,false);
            }  
      }
      
      function addCompoundNoSubdivision(cursor, numerator, denominator){
            cursor.setDuration(3, denominator);
            cursor.addNote(76,false);
            cursor.addNote(77,true);
            var notesToAdd = numerator / 3 - 1;

            for(var j = 0;j < notesToAdd; j++){

                cursor.addNote(77 ,false);
            }
      }
      
      function addSimpleOrAsymetrical(cursor, numerator, denominator){
            cursor.setDuration(1, denominator);
            cursor.addNote(76,false);
            cursor.addNote(77,true);            
            var notesToAdd = numerator - 1;
            
            for(var j = 0;j < notesToAdd; j++){
                cursor.addNote(77 ,false);
            }
      }
       
      function setVelocities(cursor){
            var numMeasures = curScore.nmeasures;           

            for (var i = 0; i < numMeasures; i++){
                  var numerator = cursor.measure.timesigActual.numerator;
                  var denominator = cursor.measure.timesigActual.denominator;
                  
                  // set downbeat
                  setNoteVelocity(cursor, 127);
                  
                  // set other beats
                  // compound 
                  if (numerator % 3 == 0 && numerator > 3){
                        // compound subdivided
                        if(cursor.tempo < 12.0 / denominator){
                              for(var j = 1;j < numerator; j++){
                                    // stressed
                                    if (j % 6 == 0){
                                          setNoteVelocity(cursor, 127);
                                    }
                                    // unstressed
                                    else if ((j + 3) % 6 == 0){
                                          setNoteVelocity(cursor, 100);
                                    }
                                    // subbeat
                                    else{
                                          setNoteVelocity(cursor, 60);
                                    }
                              } 
                        // compound not subdivided
                        }else{
                              for(var j = 1;j < numerator / 3; j++){
                                    // stressed
                                    if (j % 2 == 0 && numerator != 3){
                                          setNoteVelocity(cursor, 127);
                                    }
                                    // unstressed
                                    else{
                                          setNoteVelocity(cursor, 100);
                                    }
                              
                              }                        
                        }     
                     
                  // simple
                  }else{
                        for(var j = 1;j < numerator; j++){
                              // stressed
                              if (j % 2 == 0 && numerator != 3){
                                    setNoteVelocity(cursor, 127);
                              }
                              // unstressed
                              else{
                                    setNoteVelocity(cursor, 100);
                              }
                              
                        }                        
                  }
                    
            }
      }
      
      function setNoteVelocity(cursor, velocity){
                  var notes = cursor.element.notes;
                  for(var j = 0; j < notes.length; j++){
                       notes[j].veloType = 1;
                       notes[j].veloOffset = velocity;
                  }
                  cursor.next();
      }
     
}
