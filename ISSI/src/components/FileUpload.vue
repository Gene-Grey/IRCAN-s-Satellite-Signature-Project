<template>
  <div class="upload">
    <body>
      <section id="story_breadcrumb" class="story_breadcrumb hide">
      </section>

      <section id="drag_zone" class="drag_zone">
            <p class="drag_explanation">Drag & Drop your JSON files</p>
      </section>

      <section id="drag_document" class="drag_document">
      </section>
    </body>
  </div>
</template>

<script>   

export default {
  name: 'upload',
  data () {
      
      return {
          jsonInput: '',
      }
  },

  mounted() {
    var holder = document.getElementById('drag_zone');
    (function () {

        holder.ondragover = () => {
        	// drag_zone-hover
        	holder.classList.add("drag_zone-hover");
            return false;
        };

        holder.ondragleave = () => {
        	holder.classList.remove("drag_zone-hover");
            return false;
        };

        holder.ondragend = () => {
        	holder.classList.remove("drag_zone-hover");
            return false;
        };

        holder.ondrop = (e) => {
        	holder.classList.remove("drag_zone-hover");
            e.preventDefault();

            for (let f of e.dataTransfer.files) {
                console.log('File(s) you dragged here: ', f.path, f.type)
                switch(f.type){
                    case "application/json":
                        console.log("Display TextArea with content");
                        fetch(f.path).then((resp) => resp.text()).then(function(data) {
                            document.getElementById("drag_document").innerText = "";
                            document.getElementById("drag_document").innerText = data;
                            alert("Success : Here is displayed your JSON file");
                        });
                    break;

                    case "text/plain":
                        alert("Success : Let's process your FASTQ or TEXT file");
                    break;

                    default:
                        alert("Sorry : This is not the kind of file we are wainting for...");
                    break;
                }
             }
        }

        return false;
        
    })();
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
@-webkit-keyframes shadow-drop-2-bottom {
  0% {
    -webkit-transform: translateZ(0) translateY(0);
            transform: translateZ(0) translateY(0);
    -webkit-box-shadow: 0 0 0 0 rgba(0, 0, 0, 0);
            box-shadow: 0 0 0 0 rgba(0, 0, 0, 0);
  }
  100% {
    -webkit-transform: translateZ(50px) translateY(-12px);
            transform: translateZ(50px) translateY(-12px);
    -webkit-box-shadow: 0 12px 20px -12px rgba(0, 0, 0, 0.35);
            box-shadow: 0 12px 20px -12px rgba(0, 0, 0, 0.35);
  }
}
@keyframes shadow-drop-2-bottom {
  0% {
    -webkit-transform: translateZ(0) translateY(0);
            transform: translateZ(0) translateY(0);
    -webkit-box-shadow: 0 0 0 0 rgba(0, 0, 0, 0);
            box-shadow: 0 0 0 0 rgba(0, 0, 0, 0);
  }
  100% {
    -webkit-transform: translateZ(50px) translateY(-12px);
            transform: translateZ(50px) translateY(-12px);
    -webkit-box-shadow: 0 12px 20px -12px rgba(0, 0, 0, 0.35);
            box-shadow: 0 12px 20px -12px rgba(0, 0, 0, 0.35);
  }
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  margin: auto;
  max-width: 38rem;
  padding: 2rem;
  text-align: center;
  background-color: #FFF;
}

.drag_zone {
	background-color: lightsteelblue;
	transition: 250ms;
	border: 1px solid #333;
	min-height: 25vh;
	line-height: 25
}

.drag_zone-hover {
	background-color: lightskyblue;
	-webkit-animation: shadow-drop-2-bottom 0.4s cubic-bezier(0.250, 0.460, 0.450, 0.940) both;
	animation: shadow-drop-2-bottom 0.4s cubic-bezier(0.250, 0.460, 0.450, 0.940) both;
}

.drag_explanation {
	color: midnightblue;
	font-weight: 900;
	letter-spacing: .5rem;
	text-transform: uppercase;
	transition: 250ms;
}

.drag_zone-hover .drag_explanation {
	color: aliceblue;
}

.drag_document {
	text-align: left;
	font-size: .75rem;
	line-height: 1.5rem;
	border: 1px solid #CCC;
	padding: 1rem;
}

.drag_explanation {
	text-align: ce,ter
}

.hide {
	opacity: 0;
	user-select: none;
}

.show {
	opacity: 1;
	user-select: all;
}
</style>
