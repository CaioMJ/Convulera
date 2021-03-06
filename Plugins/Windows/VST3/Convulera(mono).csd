//LICENSE
/*
Convulera, a simple and straightforward audio convolution plugin
Copyright (C) 2020 Caio M. Jiacomini
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

<Cabbage>
form caption("Convulera (Mono) by Caio M. Jiacomini") size(450, 450), colour(0, 0, 0), pluginid("cjc1")
label bounds(72, 10, 296, 38) text("C O N V U L E R A") fontcolour(188, 151, 49, 255) colour(0, 0, 0, 255)
label bounds(110, 54, 212, 22) text("by Caio M. Jiacomini") colour(255, 255, 255, 0) fontcolour(255, 255, 255, 255)

filebutton bounds(18, 238, 158, 46) channel("FilePath") fontcolour:0(188, 151, 49, 255)

label bounds(18, 218, 158, 19) text("Load Impulse") fontcolour(255, 255, 255, 255)
soundfiler bounds(0, 312, 450, 138) identchannel("FileDisplay") colour(188, 151, 49, 255) 

label bounds(16, 108, 158, 19) text("Internal Buffer") fontcolour(255, 255, 255, 255)
combobox bounds(16, 126, 160, 43) text("4", "8", "16", "32", "64", "128", "256", "512", "1024", "2048", "4096") channel("BufferSize") value(8) fontcolour(188, 151, 49, 255) align("centre")

label bounds(270, 108, 158, 19) text("In Gain") fontcolour(255, 255, 255, 255)
hslider bounds(270, 126, 155, 25) range(-40, 20, 0, 1, 0.01) channel("InVolume") trackercolour(188, 151, 49, 255) 

label bounds(270, 234, 158, 19) text("Out Gain") fontcolour(255, 255, 255, 255)
hslider bounds(270, 252, 155, 25) range(-40, 20, 0, 1, 0.01) channel("OutVolume") trackercolour(188, 151, 49, 255) 

label bounds(270, 170, 158, 19) text("Dry/Wet") fontcolour(255, 255, 255, 255)
hslider bounds(270, 188, 155, 25) range(0, 1, 1, 1, 0.001) channel("DryWet") trackercolour(188, 151, 49, 255)


</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d 
</CsOptions>
<CsInstruments>
ksmps = 32
nchnls = 2
0dbfs = 1

instr 1
    gSfilepath  chnget  "FilePath"
    kFileChanged changed gSfilepath 

    if kFileChanged == 1 then 
        event   "i", 2, 0, 0  
        event   "i", -3, 0, 0
        event   "i", 3, 0.1, 60*60*24*7
    endif  
endin

instr   2 ;LOAD SOUND FILE     
    if filevalid(gSfilepath) == 1 then
        giChannels filenchnls gSfilepath
        Smessage sprintfk "file(\"%s\")", gSfilepath
        chnset Smessage, "FileDisplay"  
    endif
endin

instr 3 ;Convolution
//CHNGET
    giBufferSize chnget "BufferSize"
    kInVolume chnget "InVolume"
    kInVolume port kInVolume, 0.02
    kOutVolume chnget "OutVolume"
    kOutVolume port kOutVolume, 0.02
    kDryWet chnget "DryWet"
    kDryWet port kDryWet, 0.02
    
//INPUTS  
    aInL, aInR ins
    kInVolume = ampdb(kInVolume)
    kOutVolume = ampdb(kOutVolume)
    aIn = (aInL + aInR) * kInVolume
    
//SET BUFFER
    if giBufferSize == 1 then
        iPartitionSize = 4
    elseif giBufferSize == 2 then
        iPartitionSize = 8
    elseif giBufferSize == 3 then
        iPartitionSize = 16
    elseif giBufferSize == 4 then
        iPartitionSize = 32
    elseif giBufferSize == 5 then
        iPartitionSize = 64
    elseif giBufferSize == 6 then
        iPartitionSize = 128
    elseif giBufferSize == 7 then
        iPartitionSize = 256
    elseif giBufferSize == 8 then
        iPartitionSize = 512
    elseif giBufferSize == 9 then
        iPartitionSize = 1024
    elseif giBufferSize == 10 then
        iPartitionSize = 2048
    elseif giBufferSize == 11 then
        iPartitionSize = 4096
    endif

    ;print iPartitionSize, giBufferSize
    
//CHECK IF IR IS MONO OR STEREO AND CONVOLVES
    if giChannels == 1 then
        aConvolve pconvolve aIn, gSfilepath, iPartitionSize
        aIn delay aIn, iPartitionSize/sr
     
        aOut ntrpol aIn,aConvolve * 0.1, kDryWet  
        aOut clip aOut, 0, 1, 0.9
        
        outs aOut * kOutVolume, aOut * kOutVolume
            
    elseif giChannels== 2 then
        aConvolveL, aConvolveR pconvolve aIn, gSfilepath, iPartitionSize           
        aIn delay aIn, iPartitionSize/sr
        
        aOutL ntrpol aIn, aConvolveL * 0.1, kDryWet
        aOutR ntrpol aIn, aConvolveR * 0.1, kDryWet    
        
        aOutL clip aOutL, 0, 1, 0.9
        aOutR clip aOutR, 0, 1, 0.9
        
        outs aOutL * kOutVolume, aOutR * kOutVolume 
    endif
endin

</CsInstruments>
<CsScore>
i 1 0 [60*60*24*7] 
</CsScore>
</CsoundSynthesizer>
