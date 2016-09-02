# ObjectNet3D_toolbox

Created by Yu Xiang at CVGL at Stanford University.

### Introduction

This is the toolbox for the [ObjectNet3D database](http://cvgl.stanford.edu/projects/objectnet3d/) introduced for 3D object recognition.
ObjectNet3D consists of 100 categories, 90,127 images, 201,888 objects in these images. 
Objects in the images in our database are aligned with the 3D shapes, 
and the alignment provides both accurate 3D pose annotation and the closest 
3D shape annotation for each 2D object.

### License

ObjectNet3D is released under the MIT License (refer to the LICENSE file for details).

### Citing ObjectNet3D

If you find ObjectNet3D useful in your research, please consider citing:

    @incollection{xiang2016objectnet3d,
        author = {Xiang, Yu and Kim, Wonhui and Chen, Wei and Ji, Jingwei and Choy, Christopher 
               and Su, Hao and Mottaghi, Roozbeh and Guibas, Leonidas and Savarese, Silvio},
        title = {ObjectNet3D: A Large Scale Database for 3D Object Recognition},
        booktitle = {European Conference Computer Vision (ECCV)},
        year = {2016}
    }

### Usage

1. Set your paths of ObjectNet3D (required) and ShapeNetCore (optional) in globals.m.

2. annotate_pose.* is the MATLAB annotation tool we used to align 3D shapes with 2D objects.

3. draw_cad* displays the 3D CAD models we collected from [3D Warehouse](https://3dwarehouse.sketchup.com) in our annotation process.

4. show_pose_annotations.m displays the overlays of 3D shapes onto images according to our annotations. Check the code of this function to understand the annotation format of ObjectNet3D.

5. show_shapenet_annotations.m displays the retrieved 3D shapes from ShapeNetCore for objects in 42 categories.
