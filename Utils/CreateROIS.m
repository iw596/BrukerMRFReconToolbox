function CreateROIS(img)
       roiwindow = CROIEditor(mat2gray(img));

       addlistener(roiwindow,'MaskDefined',@your_roi_defined_callback)

       function your_roi_defined_callback(h,e)
            [mask, labels, n] = roiwindow.getROIData;
            delete(roiwindow); 
       end
end