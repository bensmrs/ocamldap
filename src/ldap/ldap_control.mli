(* Flow control primitives

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  Copyright (C) 2022 Benjamin Somers

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

(** Flow control primitives for proper socket handling *)

type op = Read | Write

(** generic socket type *)
type ld_socket = Ssl of Ssl.socket
               | Plain of Unix.file_descr

(** close a connection *)
val close : ld_socket -> unit

(** wrap a socket operation and allow it to time out *)
val wrap : op -> float -> ld_socket -> bytes -> int -> int -> int

(** establish a connection *)
val connect : [`PLAIN | `SSL] -> float -> Unix.file_descr -> Unix.sockaddr -> ld_socket
