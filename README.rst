Vision Stéréoscopique (2006)
============================

About
-----

My diploma work done years ago to graduate as telecommunications engineer.

This project is made available in GitHub (`repository <https://github.com/davidfischer-ch/vision-stereo.git>`_) to provide to VHDL coders some more code snippets.
It is actually implemented in French and translation is not planned, however, do not hesitate to contact me to get more explanations.

* ``code`` Source-code of the project
    * ``FPGA_Cpp`` Software implementation of various algorithms thus permit to validate corresponding VHDL implementations
    * ``FPGA_Debug`` Some VHDL code to test and ease the handling of the boards (e.g. pins assignement, ...)
    * ``FPGA_VHDL`` Pure-VHDL implementation of the embedded system, the main part of the project
    * ``FX2_Firmware`` Cypress FX2 firmware (unfinished work)
    * ``FX2_Logiciel_DDRAW`` The PC / receiver part of the demonstrator (unfinished work)
    * ``cleanup.bat`` and ``cleanup.sh`` Cleanup script (remove compilation's intermediate files)
* ``docs`` Some documentation (datasheets, boards, photos)
* ``report`` My diploma thesis

References
----------

Algorithms
^^^^^^^^^^

* `Cours de traitement d'images <http://www.ensta.fr/~manzaner/Support_Cours.html>`_ 
* `Cours de morphologie mathématique <http://cmm.ensmp.fr/~serra/cours/index.htm>`_
* `Comparison of Tracking Techniques <http://www.diku.dk/~panic/eyegaze/node12.html#SECTION00064000000000000000>`_
* `Iris Recognition with CASIA Database <http://studentweb.ncnu.edu.tw/92321049/>`_
* `2D edge detection w.cost minimiz/snakes <http://www.deeba.ro/ssip/abstract.htm>`_
* `Canny Edge Detector by Chien-I Liao <http://cs.nyu.edu/~cil217/Vision/vision_edge_detector.htm>`_
* Wikipedia `Canny edge detector <http://en.wikipedia.org/wiki/Canny_edge_detector>`_
* Wikipedia `HSL and HSV <http://en.wikipedia.org/wiki/HLS_color_space>`_

Hardware
^^^^^^^^

* Altera `Cyclone FPGA <http://www.altera.com/products/devices/cyclone/cyc-index.jsp>`_
* DigChip `IC database <http://www.digchip.com/>`_
* National Semiconductor `Main page <http://www.national.com/>`_
* RokEPXA board from EPFL `(broken link) <http://lamipc54.epfl.ch/realtimeembeddedsystems/RokEPXA/>`_ and `SOC/ARM Module on FPGAi <http://ic-sg.epfl.ch/projets_dipl/form/oldPages/page2003SIN.html>`_

Misc
^^^^

* Microsoft `Using Video Capture <http://msdn.microsoft.com/library/default.asp?url=/library/en-us/multimed/htm/_win32_capturing_data.asp>`_
* ONVERSITY `Norme IEEE 754 <http://www.onversity.net/cgi-bin/progactu/actu_aff.cgi?Eudo=bgteob&P=00000453>`_
* CSEE `VHDL samples <http://www.csee.umbc.edu/help/VHDL/samples/samples.shtml>`_

----

Kind Regards,

David Fischer
