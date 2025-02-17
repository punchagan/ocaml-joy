open Shape
open Context
open Util

let draw_circle ctx ({ c; radius; stroke; fill } : circle) =
  let stroke_circle stroke =
    set_color stroke;
    Cairo.stroke_preserve ctx.ctx
  in
  let fill_circle fill =
    set_color fill;
    Cairo.fill_preserve ctx.ctx
  in
  Cairo.arc ctx.ctx c.x (Float.neg c.y) ~r:radius ~a1:0. ~a2:(Float.pi *. 2.);
  Option.iter stroke_circle stroke;
  Option.iter fill_circle fill;
  Cairo.Path.clear ctx.ctx

let draw_ellipse ctx { c; rx; ry; stroke; fill } =
  let stroke_ellipse stroke =
    set_color stroke;
    Cairo.stroke_preserve ctx.ctx
  in
  let fill_ellipse fill =
    set_color fill;
    Cairo.fill_preserve ctx.ctx
  in

  (* Save the current transformation matrix *)
  let save_matrix = Cairo.get_matrix ctx.ctx in

  (* Translate and scale to create an ellipse from a circle *)
  Cairo.translate ctx.ctx c.x (Float.neg c.y);
  Cairo.scale ctx.ctx rx ry;
  Cairo.arc ctx.ctx 0. 0. ~r:1. ~a1:0. ~a2:(2. *. Float.pi);

  (* Restore the original transformation matrix *)
  Cairo.set_matrix ctx.ctx save_matrix;

  Option.iter stroke_ellipse stroke;
  Option.iter fill_ellipse fill;
  Cairo.Path.clear ctx.ctx

let draw_line ctx { a; b; stroke } =
  set_color stroke;
  let { x; y } = a in
  Cairo.move_to ctx.ctx x (Float.neg y);
  let { x; y } = b in
  Cairo.line_to ctx.ctx x (Float.neg y);
  Cairo.stroke ctx.ctx

let draw_polygon ctx { vertices; stroke; fill } =
  let stroke_rect stroke =
    set_color stroke;
    Cairo.stroke_preserve ctx.ctx
  in
  let fill_rect fill =
    set_color fill;
    Cairo.fill_preserve ctx.ctx
  in
  let { x; y }, t = (List.hd vertices, List.tl vertices) in
  Cairo.move_to ctx.ctx x (Float.neg y);
  List.iter
    (fun { x = x'; y = y' } -> Cairo.line_to ctx.ctx x' (Float.neg y'))
    t;
  Cairo.Path.close ctx.ctx;
  Option.iter stroke_rect stroke;
  Option.iter fill_rect fill;
  Cairo.Path.clear ctx.ctx

(* Validates context before rendering *)
let show shapes =
  let rec render ctx = function
    | Circle circle -> draw_circle ctx circle
    | Ellipse ellipse -> draw_ellipse ctx ellipse
    | Line line -> draw_line ctx line
    | Polygon polygon -> draw_polygon ctx polygon
    | Complex complex -> List.iter (render ctx) complex
  in
  match !context with
  | Some ctx -> List.iter (render ctx) shapes
  | None -> fail ()

let render_axes () =
  let x, y = resolution () |> tmap float_of_int in
  let half_x, half_y = (x /. 2., y /. 2.) in
  let x_axis = line ~a:{ x = 0.; y = -.half_y } { x = 0.; y = half_y } in
  let y_axis = line ~a:{ x = -.half_x; y = 0. } { x = half_x; y = 0. } in
  show [ x_axis; y_axis ]
