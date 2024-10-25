# Document2Audio: A document to audio conversion tool for MacOS (Copyright (C) 2024, Shyamal Suhana Chandra)
Document2Audio: A conversion shell script that converts a PDF to PNG to TEXT (with OCR) to AIFF in one script with a single command to create a M3U playlist for VLC and Mplayer playback.

# Abstract:
Imagine a world where you can convert any type into another type.  Welcome to the world of conversion tools using bash shell script!  Using the script that is provided, you can convert any arbitrary PDF into a PNG, which is an image format.  From there, you can convert the PNG file format into tax using optical character recognition. Finally, you can convert the ASCII text into AIFF file which is an audio format that is compatible with all the major music players on MacOS.  Thus, when you're on a rush or your jogging to work or playing some music in the background while studying and doing two things concurrently, this solution is for you so you can just take the bash script once all the requirements are installed and provide a one line command to convert between PDF to the AIFF file format with a M3U playlist added to work with VLC and mplayer.  Enjoy this world!

# Instructions To Install:
1. Run the following commnad.
```
brew tap Sapana-Micro-Software/formulae
```
2. Install the document2audio with the following command on MacOS 15.0.1 Sequoia
```
brew install document2audio
```
3. Change the permission so it is accessible from user mode (prompts for adminstrator password)
```
sudo chmod 755 $(brew --prefix)/bin/document2audio
```

Done and enjoy!
