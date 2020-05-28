<template>
  <div id="App">
    <div class="jumbotron text-center" style="margin-bottom:0">
      <div class="display-2">
        I S S I
      </div>
      <p>IRCAN's Satellite Signature Interface</p> 
    </div>

    <div style="height: 12px; background-color: #343a40"></div>

    <div id="Connection">
      <form class="bg-dark" id="UserForm">
        <div class="form-row">
          <div id="connection" class="form-group col-md-1"> 
            Connection 
          </div>
          <div class="form-group col-md-5 text-white">
            <label for="inputEmail">Email</label>
            <input type="email" class="form-control" id="inputEmail" placeholder="Email">
          </div>
          <div class="form-group col-md-5 text-white">
            <label for="inputPassword">Password</label>
            <input type="password" class="form-control" id="inputPassword" placeholder="Password">
          </div>
        </div>
        <div class="form-row justify-content-center">
          <div class="form-group">
            <button type="submit" class="btn btn-primary" onclick="signIn()">Sign in</button>
          </div>
        </div>
      </form>
      
      <form class="bg-dark">
        <div class="form-row justify-content-center">
          <div style="height: 24px; background-color: #343a40"></div>
          <button type="submit" class="btn btn-primary" style="margin: 0.1%">New user</button>
          <button type="submit" class="btn btn-primary" style="margin: 0.1%">Forgot password ? (That happens)</button>
        </div>
      </form>
    </div>

    <nav class="navbar navbar-expand-sm bg-dark navbar-dark" id="navbar">
      <router-link class="navbar-brand" v-bind:to="'/'">Home</router-link>
      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#collapsibleNavbar">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse justify-content-center" id="collapsibleNavbar">  
        <ul class="navbar-nav">
          <li class="nav-item">
            <router-link class="nav-link" v-bind:to="'/upload'">Upload</router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" v-bind:to="'/table'">Dataset analysis</router-link>
          </li>
          <li class="nav-item">
            <router-link class="nav-link" v-bind:to="'/about'">About</router-link>
          </li>
      </ul>
      </div>  
    </nav>
<br>
<br>
  <router-view/>
  </div>
</template>

<script>
  export default {
    name: 'App',

    data() {
    
      return{
        maker: "Joris Argentin"
      }
    },

    methods: {
      signIn() {
        var element = document.getElementById("Connection");
        element.parentNode.removeChild(element);
      },
    }
  }
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
@import url("https://maxcdn.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css");


.btn-primary{
    background-color: #0e75b7;
}

.container {
    width: 90%;
    max-width: 4000px;
}

.form-row {
    margin-right: 0px;
    margin-left: 0px;
    padding: .5rem 1rem;
}

.metadata {
    padding: 5px;

    margin: 2px; 
    
    overflow: auto;
    white-space: pre-wrap;
    background-color:white;
}

.metadata:empty {
    display:none;
}

.sticky {
    position: fixed;
    top: 0;
    width: 100%;
}

.sticky + .content {
    padding-top: 60px;
}

#connection {
    text-align: left;
    margin-right: 1rem;
    font-size: 1.25rem;
    color: #fff;
}


#fastaInput {
    position: absolute;
    width: 45%;
    text-align: center;
}

#justOr {
    position: absolute;
    width: 10%;
    left: 45%;
    margin: auto;
    text-align: center;
}


#signatureInput {
    position: absolute;
    width: 45%;
    left: 55%;
    text-align: center;
}
</style>
